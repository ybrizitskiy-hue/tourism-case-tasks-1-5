unit MainWebModule;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  Web.HTTPApp,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef;

type
  TWebModuleMain = class(TWebModule)
  private
    FConnection: TFDConnection;
    procedure ConfigureConnection;
    procedure EnsureConnected;
    procedure BeforeDispatchHandler(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure ShowHome(Response: TWebResponse);
    procedure ShowOrders(Response: TWebResponse);
    procedure ShowNewOrderForm(Response: TWebResponse);
    procedure CreateOrder(Request: TWebRequest; Response: TWebResponse);
    procedure ShowHealth(Response: TWebResponse);
    function HtmlPage(const ATitle, ABody: string): string;
    function HtmlEscape(const Value: string): string;
    function SelectOptions(const SqlText, IdField, TextField: string): string;
    function ParseIsoDate(const Value: string): TDateTime;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  WebModuleClass: TComponentClass = TWebModuleMain;

implementation

type
  EInputValidationError = class(Exception);

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

constructor TWebModuleMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FConnection := TFDConnection.Create(Self);
  ConfigureConnection;

  BeforeDispatch := BeforeDispatchHandler;
end;

procedure TWebModuleMain.ConfigureConnection;
var
  Ini: TIniFile;
  IniName: string;
  UseWindowsAuth: Boolean;
begin
  IniName := IncludeTrailingPathDelimiter(ExtractFilePath(GetModuleName(HInstance))) +
    'config.ini';

  if not FileExists(IniName) then
    raise Exception.Create('Не найден файл config.ini рядом с DLL приложения.');

  Ini := TIniFile.Create(IniName);
  try
    FConnection.LoginPrompt := False;
    FConnection.Params.Clear;
    FConnection.Params.Values['DriverID'] := 'MSSQL';
    FConnection.Params.Values['Server'] := Ini.ReadString('database', 'server', 'localhost');
    FConnection.Params.Values['Database'] := Ini.ReadString('database', 'database', 'TourismWeb');

    UseWindowsAuth := Ini.ReadBool('database', 'windows_auth', True);
    if UseWindowsAuth then
      FConnection.Params.Values['OSAuthent'] := 'Yes'
    else
    begin
      FConnection.Params.Values['OSAuthent'] := 'No';
      FConnection.Params.Values['User_Name'] := Ini.ReadString('database', 'user', '');
      FConnection.Params.Values['Password'] := Ini.ReadString('database', 'password', '');
    end;
  finally
    Ini.Free;
  end;
end;

procedure TWebModuleMain.EnsureConnected;
begin
  if not FConnection.Connected then
    FConnection.Connected := True;
end;

function TWebModuleMain.HtmlEscape(const Value: string): string;
begin
  Result := StringReplace(Value, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

function TWebModuleMain.HtmlPage(const ATitle, ABody: string): string;
begin
  Result :=
    '<!doctype html>' +
    '<html lang="ru">' +
    '<head>' +
      '<meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width, initial-scale=1">' +
      '<title>' + HtmlEscape(ATitle) + '</title>' +
      '<style>' +
        'body{font-family:Arial,sans-serif;margin:0;background:#f4f6f8;color:#222;}' +
        '.wrap{max-width:1050px;margin:30px auto;background:#fff;padding:24px;' +
          'border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,.08);}' +
        'nav{margin-bottom:24px;}nav a{margin-right:16px;color:#1f5fa8;text-decoration:none;}' +
        'table{width:100%;border-collapse:collapse;margin-top:16px;}' +
        'th,td{border:1px solid #d7dce2;padding:8px;text-align:left;}' +
        'th{background:#eef2f6;}' +
        'label{display:block;margin-top:12px;font-weight:bold;}' +
        'input,select{width:100%;max-width:480px;padding:8px;margin-top:5px;' +
          'box-sizing:border-box;}' +
        'button{margin-top:18px;padding:10px 18px;border:0;border-radius:5px;' +
          'background:#1f5fa8;color:white;cursor:pointer;}' +
        '.ok{padding:12px;background:#e8f5e9;border:1px solid #a5d6a7;}' +
      '</style>' +
    '</head>' +
    '<body><div class="wrap">' +
      '<nav>' +
        '<a href="./">Главная</a>' +
        '<a href="orders">Заказы</a>' +
        '<a href="new-order">Новый заказ</a>' +
      '</nav>' +
      ABody +
    '</div></body></html>';
end;

procedure TWebModuleMain.BeforeDispatchHandler(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  Path: string;
begin
  if Handled then
    Exit;

  Path := LowerCase(Request.PathInfo);
  if Path = '' then
    Path := '/';

  try
    if (Path = '/') then
      ShowHome(Response)
    else if (Path = '/orders') then
      ShowOrders(Response)
    else if (Path = '/new-order') and SameText(Request.Method, 'GET') then
      ShowNewOrderForm(Response)
    else if (Path = '/create-order') and SameText(Request.Method, 'POST') then
      CreateOrder(Request, Response)
    else if (Path = '/health') then
      ShowHealth(Response)
    else
    begin
      Response.StatusCode := 404;
      Response.ContentType := 'text/html; charset=utf-8';
      Response.Content := HtmlPage('Страница не найдена',
        '<h1>404</h1><p>Запрошенная страница не найдена.</p>');
    end;
  except
    on E: EInputValidationError do
    begin
      Response.StatusCode := 400;
      Response.ContentType := 'text/html; charset=utf-8';
      Response.Content := HtmlPage('Некорректные данные',
        '<h1>Не удалось создать заказ</h1><p>' + HtmlEscape(E.Message) + '</p>');
    end;
    on E: Exception do
    begin
      Response.StatusCode := 500;
      Response.ContentType := 'text/html; charset=utf-8';
      Response.Content := HtmlPage('Ошибка',
        '<h1>Ошибка приложения</h1>' +
        '<p>Не удалось обработать запрос. Проверьте настройки приложения и подключение к базе данных.</p>');
    end;
  end;

  Handled := True;
end;

procedure TWebModuleMain.ShowHome(Response: TWebResponse);
begin
  Response.ContentType := 'text/html; charset=utf-8';
  Response.Content := HtmlPage('Туристическая компания',
    '<h1>Учет заказов туристической компании</h1>' +
    '<p>Учебное WEB-приложение позволяет просматривать оформленные заказы ' +
    'и создавать новые заказы.</p>' +
    '<p><a href="orders">Открыть список заказов</a></p>' +
    '<p><a href="new-order">Оформить новый заказ</a></p>');
end;

procedure TWebModuleMain.ShowHealth(Response: TWebResponse);
begin
  EnsureConnected;
  Response.ContentType := 'text/plain; charset=utf-8';
  Response.Content := 'OK';
end;

procedure TWebModuleMain.ShowOrders(Response: TWebResponse);
var
  Query: TFDQuery;
  Body: string;
begin
  EnsureConnected;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'SELECT o.OrderID, c.FullName, co.CountryName, h.City, h.HotelName, ' +
      'tt.TypeName, o.DateFrom, o.DateTo, o.PersonsCount, o.TotalPrice, o.Status ' +
      'FROM dbo.TourOrders o ' +
      'JOIN dbo.Clients c ON c.ClientID = o.ClientID ' +
      'JOIN dbo.Hotels h ON h.HotelID = o.HotelID ' +
      'JOIN dbo.Countries co ON co.CountryID = h.CountryID ' +
      'JOIN dbo.TourTypes tt ON tt.TourTypeID = o.TourTypeID ' +
      'ORDER BY o.OrderID DESC';
    Query.Open;

    Body := '<h1>Заказы туров</h1>' +
      '<table><tr>' +
      '<th>ID</th><th>Клиент</th><th>Страна</th><th>Город</th>' +
      '<th>Отель</th><th>Тип</th><th>С</th><th>По</th>' +
      '<th>Туристов</th><th>Стоимость</th><th>Статус</th></tr>';

    while not Query.Eof do
    begin
      Body := Body + '<tr>' +
        '<td>' + Query.FieldByName('OrderID').AsString + '</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('FullName').AsString) + '</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('CountryName').AsString) + '</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('City').AsString) + '</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('HotelName').AsString) + '</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('TypeName').AsString) + '</td>' +
        '<td>' + FormatDateTime('yyyy-mm-dd', Query.FieldByName('DateFrom').AsDateTime) + '</td>' +
        '<td>' + FormatDateTime('yyyy-mm-dd', Query.FieldByName('DateTo').AsDateTime) + '</td>' +
        '<td>' + Query.FieldByName('PersonsCount').AsString + '</td>' +
        '<td>' + FormatFloat('0.00', Query.FieldByName('TotalPrice').AsFloat) + ' EUR</td>' +
        '<td>' + HtmlEscape(Query.FieldByName('Status').AsString) + '</td>' +
        '</tr>';
      Query.Next;
    end;

    Body := Body + '</table>';
    Response.ContentType := 'text/html; charset=utf-8';
    Response.Content := HtmlPage('Заказы', Body);
  finally
    Query.Free;
  end;
end;

function TWebModuleMain.SelectOptions(const SqlText, IdField,
  TextField: string): string;
var
  Query: TFDQuery;
begin
  Result := '';
  EnsureConnected;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := SqlText;
    Query.Open;

    while not Query.Eof do
    begin
      Result := Result + '<option value="' +
        Query.FieldByName(IdField).AsString + '">' +
        HtmlEscape(Query.FieldByName(TextField).AsString) + '</option>';
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

procedure TWebModuleMain.ShowNewOrderForm(Response: TWebResponse);
var
  ClientOptions: string;
  HotelOptions: string;
  TypeOptions: string;
  Body: string;
begin
  ClientOptions := SelectOptions(
    'SELECT ClientID, FullName FROM dbo.Clients ORDER BY FullName',
    'ClientID', 'FullName');

  HotelOptions := SelectOptions(
    'SELECT h.HotelID, co.CountryName + N'' — '' + h.City + N'' — '' + h.HotelName AS DisplayName ' +
    'FROM dbo.Hotels h JOIN dbo.Countries co ON co.CountryID = h.CountryID ' +
    'ORDER BY co.CountryName, h.City, h.HotelName',
    'HotelID', 'DisplayName');

  TypeOptions := SelectOptions(
    'SELECT TourTypeID, TypeName FROM dbo.TourTypes ORDER BY TypeName',
    'TourTypeID', 'TypeName');

  Body :=
    '<h1>Новый заказ</h1>' +
    '<form method="post" action="create-order">' +
      '<label>Клиент</label>' +
      '<select name="client_id" required>' + ClientOptions + '</select>' +
      '<label>Отель</label>' +
      '<select name="hotel_id" required>' + HotelOptions + '</select>' +
      '<label>Тип тура</label>' +
      '<select name="tour_type_id" required>' + TypeOptions + '</select>' +
      '<label>Дата начала</label>' +
      '<input type="date" name="date_from" required>' +
      '<label>Дата окончания</label>' +
      '<input type="date" name="date_to" required>' +
      '<label>Количество туристов</label>' +
      '<input type="number" name="persons_count" min="1" max="50" value="1" required>' +
      '<label>Общая стоимость, EUR</label>' +
      '<input type="number" name="total_price" min="0" step="0.01" required>' +
      '<button type="submit">Оформить заказ</button>' +
    '</form>';

  Response.ContentType := 'text/html; charset=utf-8';
  Response.Content := HtmlPage('Новый заказ', Body);
end;

function TWebModuleMain.ParseIsoDate(const Value: string): TDateTime;
var
  YearValue, MonthValue, DayValue: Integer;
begin
  if Length(Value) <> 10 then
    raise EInputValidationError.Create('Укажите дату в формате ГГГГ-ММ-ДД.');
  if (Value[5] <> '-') or (Value[8] <> '-') then
    raise EInputValidationError.Create('Укажите дату в формате ГГГГ-ММ-ДД.');

  if not TryStrToInt(Copy(Value, 1, 4), YearValue) or
     not TryStrToInt(Copy(Value, 6, 2), MonthValue) or
     not TryStrToInt(Copy(Value, 9, 2), DayValue) then
    raise EInputValidationError.Create('Укажите корректную дату.');
  if (YearValue < 1) or (YearValue > 9999) or
     (MonthValue < 1) or (MonthValue > 12) or
     (DayValue < 1) or (DayValue > 31) then
    raise EInputValidationError.Create('Укажите корректную дату.');
  try
    Result := EncodeDate(Word(YearValue), Word(MonthValue), Word(DayValue));
  except
    on E: Exception do
      raise EInputValidationError.Create('Укажите корректную дату.');
  end;
end;

procedure TWebModuleMain.CreateOrder(Request: TWebRequest;
  Response: TWebResponse);
var
  ClientId: Integer;
  HotelId: Integer;
  TourTypeId: Integer;
  PersonsCount: Integer;
  DateFrom: TDateTime;
  DateTo: TDateTime;
  TotalPrice: Currency;
  PriceText: string;
  FS: TFormatSettings;
  Query: TFDQuery;
begin
  ClientId := StrToIntDef(Request.ContentFields.Values['client_id'], 0);
  HotelId := StrToIntDef(Request.ContentFields.Values['hotel_id'], 0);
  TourTypeId := StrToIntDef(Request.ContentFields.Values['tour_type_id'], 0);
  PersonsCount := StrToIntDef(Request.ContentFields.Values['persons_count'], 0);

  DateFrom := ParseIsoDate(Request.ContentFields.Values['date_from']);
  DateTo := ParseIsoDate(Request.ContentFields.Values['date_to']);

  FS := TFormatSettings.Create('en-US');
  PriceText := StringReplace(Request.ContentFields.Values['total_price'], ',', '.', [rfReplaceAll]);
  if not TryStrToCurr(PriceText, TotalPrice, FS) then
    raise EInputValidationError.Create('Укажите корректную стоимость тура.');

  if (ClientId <= 0) or (HotelId <= 0) or (TourTypeId <= 0) then
    raise EInputValidationError.Create('Необходимо выбрать клиента, отель и тип тура.');
  if (PersonsCount < 1) or (PersonsCount > 50) then
    raise EInputValidationError.Create('Количество туристов должно быть от 1 до 50.');
  if DateTo < DateFrom then
    raise EInputValidationError.Create('Дата окончания не может быть раньше даты начала.');
  if TotalPrice < 0 then
    raise EInputValidationError.Create('Стоимость не может быть отрицательной.');
  if TotalPrice > 99999999.99 then
    raise EInputValidationError.Create('Максимальная стоимость — 99 999 999,99.');
  if Frac(TotalPrice * 100) <> 0 then
    raise EInputValidationError.Create('Стоимость можно указать не более чем с двумя знаками после запятой.');

  EnsureConnected;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'INSERT INTO dbo.TourOrders ' +
      '(ClientID, HotelID, TourTypeID, OrderDate, DateFrom, DateTo, ' +
      'PersonsCount, TotalPrice, Status) ' +
      'VALUES (:ClientID, :HotelID, :TourTypeID, CONVERT(date, GETDATE()), ' +
      ':DateFrom, :DateTo, :PersonsCount, :TotalPrice, N''Новый'')';

    Query.ParamByName('ClientID').AsInteger := ClientId;
    Query.ParamByName('HotelID').AsInteger := HotelId;
    Query.ParamByName('TourTypeID').AsInteger := TourTypeId;
    Query.ParamByName('DateFrom').AsDate := DateFrom;
    Query.ParamByName('DateTo').AsDate := DateTo;
    Query.ParamByName('PersonsCount').AsInteger := PersonsCount;
    Query.ParamByName('TotalPrice').AsCurrency := TotalPrice;
    Query.ExecSQL;
  finally
    Query.Free;
  end;

  Response.ContentType := 'text/html; charset=utf-8';
  Response.Content := HtmlPage('Заказ создан',
    '<h1>Заказ создан</h1>' +
    '<div class="ok">Новый заказ успешно сохранен в базе данных.</div>' +
    '<p><a href="orders">Перейти к списку заказов</a></p>');
end;

end.
