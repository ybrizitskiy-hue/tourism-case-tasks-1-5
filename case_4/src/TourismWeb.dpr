library TourismWeb;

uses
  System.SysUtils,
  System.Classes,
  Web.WebBroker,
  Web.Win.ISAPIApp,
  MainWebModule in 'MainWebModule.pas' {WebModuleMain: TWebModule};

exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;

begin
  Application.Initialize;
  Application.WebModuleClass := WebModuleClass;
  Application.Run;
end.
