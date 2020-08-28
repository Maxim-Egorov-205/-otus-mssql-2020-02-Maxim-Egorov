
--Нужно используя операторы DDL создать:
--1. Создать базу данных.*
--2. 3-4 основные таблицы для своего проекта.*
--3. Первичные и внешние ключи для всех созданных таблиц.*
--4. 1-2 индекса на таблицы.*
--5. Наложите по одному ограничению в каждой таблице на ввод данных.

--Создаем БД

--внешние ключи

CREATE DATABASE [Book_Shop_test]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Book_Shop', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Book_Shop_test.mdf' ,
  SIZE = 8192KB ,
  MAXSIZE = UNLIMITED,
  FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Book_Shop_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Book_Shop_test_log.ldf' ,
  SIZE = 8192KB ,
  MAXSIZE = 2048GB,
  FILEGROWTH = 65536KB )
GO;

--Создаем таблицы с первичными ключами

--01 Создаем основную таблицу
--Внешние ключи будут созданы на следующих этапах
USE [Book_Shop_test]
GO

DROP TABLE IF EXISTS [dbo].[Customers]
DROP TABLE IF EXISTS [dbo].[Addresses]
DROP TABLE IF EXISTS [dbo].[FullNames]
DROP TABLE IF EXISTS [dbo].[FirstNames]
DROP TABLE IF EXISTS [dbo].[LastNames]
DROP TABLE IF EXISTS [dbo].[Patronymics]

CREATE TABLE [dbo].[Customers](
	[CustomerID] [int] NOT NULL PRIMARY KEY,
	[FullNameID] [int] NOT NULL,
	[PhoneNumber] [varchar](50) NOT NULL CONSTRAINT CHK_PhoneNumber  CHECK (Len(PhoneNumber)<=9), --ограничение на минимальную длину записи
	[Email] [nvarchar](254) NOT NULL,
	[AddressID] [int] NULL -- допускаем значение NULL т.к. клиент может забрать заказ самовывозом ,
	

) ON [PRIMARY]

--02 Создаем таблицу с адресами Addresses
DROP TABLE IF EXISTS [dbo].[Addresses]
CREATE TABLE [dbo].[Addresses](
	[AddressID] [int] NOT NULL PRIMARY KEY ,
	[Region] [varchar](150) NULL,
	[City] [varchar](150) NULL CONSTRAINT CHK_City  CHECK (Len(City)>1),
	[Street] [varchar](150) NULL CONSTRAINT CHK_Street  CHECK (Len(Street )>5),
	[HouseNumber] [int] NULL
) ON [PRIMARY]


--03 Создаем таблицу с полными именами
CREATE TABLE [dbo].[FullNames](
	[FullNameID] [int] NOT NULL PRIMARY KEY IDENTITY(1,1),
	[FirstNameID] [int] NULL,
	[LastNameID] [int] NULL,
	[PatronymicID] [int] NULL
) ON [PRIMARY]

--04 Создаем таблицу с  именами
CREATE TABLE [dbo].[FirstNames](
	[FirstNameID] [int]  NOT NULL PRIMARY KEY IDENTITY(1,1),
	[FirstName] [varchar](254) NOT NULL
) ON [PRIMARY]

--05 Создаем таблицу с фамилиями
CREATE TABLE [dbo].[LastNames](
	[LastNameID] [int] NOT NULL PRIMARY KEY IDENTITY(1,1),
	[LastName] [varchar](254) NOT NULL
) ON [PRIMARY]

--06 Создаем таблицу с отчествами
CREATE TABLE [dbo].[Patronymics](
	[PatronymicID] [int] NOT NULL PRIMARY KEY IDENTITY(1,1),
	[Patronymic] [varchar](254) NULL
) ON [PRIMARY]

--07 создаем внешние ключи  в таблице customers
ALTER TABLE Customers  ADD  CONSTRAINT FK_AddressID FOREIGN KEY(AddressID)
REFERENCES Addresses (AddressID)

--07 создаем внешние ключи  в таблице FullNames
ALTER TABLE FullNames  ADD CONSTRAINT FK_FirstNameID FOREIGN KEY(FirstNameID)
REFERENCES FirstNames (FirstNameID)
ALTER TABLE FullNames  ADD CONSTRAINT FK_LastNameID FOREIGN KEY(LastNameID)
REFERENCES LastNames (LastNameID)
ALTER TABLE FullNames  ADD CONSTRAINT FK_PatronymicID FOREIGN KEY(PatronymicID)
REFERENCES Patronymics (PatronymicID)

--09 создаем доп индексы на каждой таблице
--Customers
CREATE NONCLUSTERED INDEX [IX_AddressID] ON [dbo].[Customers]([AddressID] ASC)

--FullNames
CREATE NONCLUSTERED INDEX [IX_FirstNameID] ON [dbo].[FullNames]([FirstNameID] ASC)
CREATE NONCLUSTERED INDEX [IX_LastNameID] ON [dbo].[FullNames]([LastNameID] ASC)
CREATE NONCLUSTERED INDEX [IX_PatronymicID] ON [dbo].[FullNames]([PatronymicID] ASC)

--сделаем составные некластерные индексы на таблицах FirstNames, LastNamrs, Patronymics, Addresses
CREATE UNIQUE NONCLUSTERED INDEX [IX_Addresses_NonClUnique] ON [dbo].[Addresses]([AddressID] ASC, [Region] ASC, [City] ASC, [Street] ASC, [HouseNumber] ASC)
CREATE UNIQUE NONCLUSTERED INDEX [IX_FirstNames_NonClUnique] ON [dbo].[FirstNames]([FirstNameID] ASC, [FirstName] ASC)
CREATE UNIQUE NONCLUSTERED INDEX [IX_LastNames_NonClUnique] ON [dbo].[LastNames]([LastNameID] ASC, [LastName] ASC)
CREATE UNIQUE NONCLUSTERED INDEX [IX_Patronymics_NonClUnique] ON [dbo].[Patronymics]([PatronymicID] ASC, [Patronymic] ASC)
