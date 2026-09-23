# Кейс-задача № 4

## Тема приложения

WEB-приложение «Учет заказов туристической компании».

Технологии по условию задания:

- Delphi 10.2 Tokyo;
- WebBroker;
- Microsoft IIS;
- ISAPI DLL;
- Microsoft SQL Server;
- FireDAC.

## Функции приложения

Приложение содержит пять HTTP-маршрутов:

- `/` — главная страница;
- `/orders` — просмотр заказов;
- `/new-order` — форма оформления нового заказа;
- `/create-order` — сохранение заказа методом POST;
- `/health` — простая проверка соединения с базой данных.

## Структура каталога

```text
case_4/
├── database/
│   └── tourism_mssql.sql
├── docs/
│   ├── architecture.txt
│   └── market_analysis.md
├── src/
│   ├── TourismWeb.dpr
│   ├── MainWebModule.pas
│   ├── MainWebModule.dfm
│   └── config.ini.example
└── README.md
```

## 1. Создание базы данных

Открыть SQL Server Management Studio и выполнить:

`database/tourism_mssql.sql`

Скрипт создаст базу `TourismWeb`, таблицы, ключи, индексы и несколько тестовых записей. При повторном запуске он удалит пять таблиц приложения вместе с их данными и создаст их заново.

## 2. Настройка Delphi 10.2

1. Открыть файл `src/TourismWeb.dpr` в Delphi 10.2.
2. Убедиться, что установлен компонент FireDAC и доступен драйвер Microsoft SQL Server.
3. Выбрать нужную платформу сборки — Win32 или Win64. Разрядность DLL должна соответствовать настройке пула приложений IIS.
4. Выполнить сборку проекта.

Результатом будет ISAPI DLL `TourismWeb.dll`.

## 3. Настройка подключения

Скопировать:

`src/config.ini.example`

в файл:

`config.ini`

и разместить его рядом с `TourismWeb.dll`.

Для Windows Authentication:

```ini
[database]
server=localhost
database=TourismWeb
windows_auth=1
```

Учетная запись пула приложений IIS должна иметь права на базу `TourismWeb`.

Для SQL Server Authentication:

```ini
[database]
server=localhost
database=TourismWeb
windows_auth=0
user=имя_пользователя
password=пароль
```

## 4. Размещение в IIS

Пример каталога:

```text
C:\inetpub\wwwroot\TourismWeb\
    TourismWeb.dll
    config.ini
```

Последовательность настройки:

1. Включить IIS и компонент `ISAPI Extensions` в компонентах Windows.
2. Создать в IIS отдельное приложение, указывающее на папку `TourismWeb`.
3. Для пула приложений установить `No Managed Code`.
4. Разрешить выполнение ISAPI DLL.
5. Если DLL собрана как Win32, включить `Enable 32-Bit Applications` для пула. Для Win64 оставить эту настройку выключенной.
6. Проверить права файловой системы на чтение DLL и `config.ini`.
7. Проверить, что учетная запись пула имеет доступ к MS SQL Server.

Пример адреса:

```text
http://localhost/TourismWeb/TourismWeb.dll/
```

Список заказов:

```text
http://localhost/TourismWeb/TourismWeb.dll/orders
```

Проверка базы:

```text
http://localhost/TourismWeb/TourismWeb.dll/health
```

При исправном подключении страница `/health` вернет `OK`.

## 5. Архитектура

```text
Browser -> IIS -> ISAPI WebBroker DLL -> FireDAC -> MS SQL Server
```

Запрос обрабатывается на сервере. HTML формируется в Delphi-коде. SQL-запросы выполняются через параметризованные запросы FireDAC.

## 6. Аналитическая часть

Описание WEB-архитектуры и сравнение существующих информационных систем находится в:

`docs/market_analysis.md`

В анализ включены Salesforce Sales Cloud, Microsoft Dynamics 365 Sales, Bitrix24 CRM и SAP Business One Web Client.
