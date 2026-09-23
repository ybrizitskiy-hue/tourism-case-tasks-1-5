IF DB_ID(N'TourismWeb') IS NULL
BEGIN
    CREATE DATABASE TourismWeb;
END;
GO

USE TourismWeb;
GO

IF OBJECT_ID(N'dbo.TourOrders', N'U') IS NOT NULL DROP TABLE dbo.TourOrders;
IF OBJECT_ID(N'dbo.Hotels', N'U') IS NOT NULL DROP TABLE dbo.Hotels;
IF OBJECT_ID(N'dbo.TourTypes', N'U') IS NOT NULL DROP TABLE dbo.TourTypes;
IF OBJECT_ID(N'dbo.Clients', N'U') IS NOT NULL DROP TABLE dbo.Clients;
IF OBJECT_ID(N'dbo.Countries', N'U') IS NOT NULL DROP TABLE dbo.Countries;
GO

CREATE TABLE dbo.Countries (
    CountryID INT IDENTITY(1, 1) NOT NULL,
    CountryName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Countries PRIMARY KEY (CountryID),
    CONSTRAINT UQ_Countries_CountryName UNIQUE (CountryName)
);
GO

CREATE TABLE dbo.Hotels (
    HotelID INT IDENTITY(1, 1) NOT NULL,
    CountryID INT NOT NULL,
    HotelName NVARCHAR(150) NOT NULL,
    Stars TINYINT NOT NULL,
    City NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Hotels PRIMARY KEY (HotelID),
    CONSTRAINT CK_Hotels_Stars CHECK (Stars BETWEEN 1 AND 5),
    CONSTRAINT FK_Hotels_Countries FOREIGN KEY (CountryID)
        REFERENCES dbo.Countries(CountryID)
);
GO

CREATE TABLE dbo.TourTypes (
    TourTypeID INT IDENTITY(1, 1) NOT NULL,
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255) NULL,
    CONSTRAINT PK_TourTypes PRIMARY KEY (TourTypeID),
    CONSTRAINT UQ_TourTypes_TypeName UNIQUE (TypeName)
);
GO

CREATE TABLE dbo.Clients (
    ClientID INT IDENTITY(1, 1) NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(30) NOT NULL,
    Email NVARCHAR(150) NULL,
    CONSTRAINT PK_Clients PRIMARY KEY (ClientID),
    CONSTRAINT UQ_Clients_Email UNIQUE (Email)
);
GO

CREATE TABLE dbo.TourOrders (
    OrderID INT IDENTITY(1, 1) NOT NULL,
    ClientID INT NOT NULL,
    HotelID INT NOT NULL,
    TourTypeID INT NOT NULL,
    OrderDate DATE NOT NULL CONSTRAINT DF_TourOrders_OrderDate DEFAULT (CONVERT(date, GETDATE())),
    DateFrom DATE NOT NULL,
    DateTo DATE NOT NULL,
    PersonsCount TINYINT NOT NULL CONSTRAINT DF_TourOrders_Persons DEFAULT (1),
    TotalPrice DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_TourOrders_Status DEFAULT (N'Новый'),
    CONSTRAINT PK_TourOrders PRIMARY KEY (OrderID),
    CONSTRAINT CK_TourOrders_Dates CHECK (DateTo >= DateFrom),
    CONSTRAINT CK_TourOrders_Persons CHECK (PersonsCount > 0),
    CONSTRAINT CK_TourOrders_Price CHECK (TotalPrice >= 0),
    CONSTRAINT FK_TourOrders_Clients FOREIGN KEY (ClientID)
        REFERENCES dbo.Clients(ClientID),
    CONSTRAINT FK_TourOrders_Hotels FOREIGN KEY (HotelID)
        REFERENCES dbo.Hotels(HotelID),
    CONSTRAINT FK_TourOrders_TourTypes FOREIGN KEY (TourTypeID)
        REFERENCES dbo.TourTypes(TourTypeID)
);
GO

CREATE INDEX IX_TourOrders_ClientID ON dbo.TourOrders(ClientID);
CREATE INDEX IX_TourOrders_HotelID ON dbo.TourOrders(HotelID);
CREATE INDEX IX_TourOrders_TourTypeID ON dbo.TourOrders(TourTypeID);
CREATE INDEX IX_TourOrders_OrderDate ON dbo.TourOrders(OrderDate);
GO

INSERT INTO dbo.Countries (CountryName) VALUES
(N'Болгария'),
(N'Италия'),
(N'Греция'),
(N'Испания');
GO

INSERT INTO dbo.Hotels (CountryID, HotelName, Stars, City) VALUES
(1, N'Sea Resort', 4, N'Солнечный Берег'),
(1, N'Marina Palace', 5, N'Несебр'),
(2, N'Roma Centro Hotel', 4, N'Рим'),
(3, N'Aegean Blue', 4, N'Салоники'),
(4, N'Costa Hotel', 4, N'Барселона');
GO

INSERT INTO dbo.TourTypes (TypeName, Description) VALUES
(N'Пляжный', N'Отдых у моря'),
(N'Экскурсионный', N'Тур с экскурсионной программой'),
(N'Семейный', N'Тур для семейного отдыха'),
(N'Городской', N'Короткая поездка в крупный город');
GO

INSERT INTO dbo.Clients (FullName, Phone, Email) VALUES
(N'Иван Иванов', N'+359888111222', N'ivan@example.com'),
(N'Мария Петрова', N'+359888222333', N'maria@example.com'),
(N'Алексей Смирнов', N'+359888333444', N'alex@example.com');
GO

INSERT INTO dbo.TourOrders
    (ClientID, HotelID, TourTypeID, DateFrom, DateTo, PersonsCount, TotalPrice, Status)
VALUES
    (1, 1, 1, '2026-10-10', '2026-10-17', 2, 1300.00, N'Подтвержден'),
    (2, 3, 4, '2026-11-06', '2026-11-09', 1, 420.00, N'Новый');
GO
