--1. ����������� � ���� 5 ������� ��������� insert � ������� Customers ��� Suppliers
USE WideWorldImporters;
--������� sequence ��� ���������� ����� CustomerID, �������  1000000 
CREATE SEQUENCE Cuctomers_PK_Seq
	AS INT 
	START WITH 1000000
	INCREMENT BY 1

--��������� ������� ������� � ���� ��� �������
INSERT INTO Sales.Customers
	(CustomerID, 
	 CustomerName, 
	 BillToCustomerID, 
	 CustomerCategoryID, 
	 BuyingGroupID,
	 PrimaryContactPersonID, 
	 AlternateContactPersonID, 
	 DeliveryMethodID, 
	 DeliveryCityID, 
	 PostalCityID, 
	 CreditLimit, 
	 AccountOpenedDate,
	 StandardDiscountPercentage, 
	 IsStatementSent, 
	 IsOnCreditHold, 
	 PaymentDays, 
	 PhoneNumber, 
	 FaxNumber, 
	 DeliveryRun, 
	 RunPosition, 
	 WebsiteURL, 
	 DeliveryAddressLine1, 
	 DeliveryAddressLine2, 
	 DeliveryPostalCode, 
	 DeliveryLocation, 
	 PostalAddressLine1, 
	 PostalAddressLine2,
	 PostalPostalCode, 
	 LastEditedBy)
--����� �� ��������� ���� �������, �������� ����� ��� 5 ������������ ������� �� ������� �������, 
--CustomerID ��������� ���������� �� SEQUENCE
--� CustomerName ��������� ����� CustomerID, ����� ������ ����������� �� ������������
SELECT NEXT VALUE FOR Cuctomers_PK_Seq,	
	    'Test_'+cast(NEXT VALUE FOR Cuctomers_PK_Seq as varchar(20))+'_'+CustomerName,
		BillToCustomerID, 
		CustomerCategoryID, 
		BuyingGroupID,
		PrimaryContactPersonID, 
		AlternateContactPersonID, 
		DeliveryMethodID, 
		DeliveryCityID, 
		PostalCityID, 
		CreditLimit, 
		AccountOpenedDate,
		StandardDiscountPercentage, 
		IsStatementSent, 
		IsOnCreditHold, 
		PaymentDays, 
		PhoneNumber, 
		FaxNumber, 
		DeliveryRun, 
		RunPosition, 
		WebsiteURL, 
		DeliveryAddressLine1, 
		DeliveryAddressLine2, 
		DeliveryPostalCode, 
		DeliveryLocation, 
		PostalAddressLine1, 
		PostalAddressLine2,
		PostalPostalCode, 
		LastEditedBy
FROM (SELECT TOP 5 * FROM Sales.Customers) AS Test_Dataset

--2. ������� 1 ������ �� Customers, ������� ���� ���� ���������
DELETE TOP (1) 
FROM Sales.Customers
WHERE CustomerID>=1000000

--3. �������� ���� ������, �� ����������� ����� UPDATE
UPDATE Sales.Customers
	SET CustomerName = 'Updated_'+CustomerName
WHERE CustomerID IN (SELECT TOP 1 CustomerID FROM Sales.Customers WHERE CustomerID>=1000000)

--4. �������� MERGE, ������� ������� ������� ������ � �������, ���� �� ��� ���, � ������� ���� ��� ��� ����
DECLARE @CustomerName nvarchar(100) = 'Bill Gates'

MERGE Sales.Customers AS Target
USING (SELECT TOP 1 CustomerID,
					CustomerName,
					BillToCustomerID, 
					CustomerCategoryID, 
					BuyingGroupID,
					PrimaryContactPersonID, 
					AlternateContactPersonID, 
					DeliveryMethodID, 
					DeliveryCityID, 
					PostalCityID, 
					CreditLimit, 
					AccountOpenedDate,
					StandardDiscountPercentage, 
					IsStatementSent, 
					IsOnCreditHold, 
					PaymentDays, 
					PhoneNumber, 
					FaxNumber, 
					DeliveryRun, 
					RunPosition, 
					WebsiteURL, 
					DeliveryAddressLine1, 
					DeliveryAddressLine2, 
					DeliveryPostalCode, 
					DeliveryLocation, 
					PostalAddressLine1, 
					PostalAddressLine2,
					PostalPostalCode, 
					LastEditedBy
		FROM Sales.Customers)
	AS source (CustomerID,
			   CustomerName,
			   BillToCustomerID, 
			   CustomerCategoryID, 
			   BuyingGroupID,
			   PrimaryContactPersonID, 
			   AlternateContactPersonID, 
			   DeliveryMethodID, 
			   DeliveryCityID, 
			   PostalCityID, 
			   CreditLimit, 
			   AccountOpenedDate,
			   StandardDiscountPercentage, 
			   IsStatementSent, 
			   IsOnCreditHold, 
			   PaymentDays, 
			   PhoneNumber, 
			   FaxNumber, 
			   DeliveryRun, 
			   RunPosition, 
			   WebsiteURL, 
			   DeliveryAddressLine1, 
			   DeliveryAddressLine2, 
			   DeliveryPostalCode, 
			   DeliveryLocation, 
			   PostalAddressLine1, 
			   PostalAddressLine2,
			   PostalPostalCode, 
			   LastEditedBy)      
	ON
	(target.CustomerID = source.CustomerID) 
WHEN MATCHED 
	THEN UPDATE SET CustomerName = @CustomerName
WHEN NOT MATCHED
	THEN INSERT (CustomerID,
			     CustomerName,
			     BillToCustomerID, 
			     CustomerCategoryID, 
			     BuyingGroupID,
			     PrimaryContactPersonID, 
			     AlternateContactPersonID, 
			     DeliveryMethodID, 
			     DeliveryCityID, 
			     PostalCityID, 
			     CreditLimit, 
			     AccountOpenedDate,
			     StandardDiscountPercentage, 
			     IsStatementSent, 
			     IsOnCreditHold, 
			     PaymentDays, 
			     PhoneNumber, 
			     FaxNumber, 
			     DeliveryRun, 
			     RunPosition, 
			     WebsiteURL, 
			     DeliveryAddressLine1, 
			     DeliveryAddressLine2, 
			     DeliveryPostalCode, 
			     DeliveryLocation, 
			     PostalAddressLine1, 
			     PostalAddressLine2,
			     PostalPostalCode, 
			     LastEditedBy)
		VALUES (CustomerID,
			     CustomerName,
			     BillToCustomerID, 
			     CustomerCategoryID, 
			     BuyingGroupID,
			     PrimaryContactPersonID, 
			     AlternateContactPersonID, 
			     DeliveryMethodID, 
			     DeliveryCityID, 
			     PostalCityID, 
			     CreditLimit, 
			     AccountOpenedDate,
			     StandardDiscountPercentage, 
			     IsStatementSent, 
			     IsOnCreditHold, 
			     PaymentDays, 
			     PhoneNumber, 
			     FaxNumber, 
			     DeliveryRun, 
			     RunPosition, 
			     WebsiteURL, 
			     DeliveryAddressLine1, 
			     DeliveryAddressLine2, 
			     DeliveryPostalCode, 
			     DeliveryLocation, 
			     PostalAddressLine1, 
			     PostalAddressLine2,
			     PostalPostalCode, 
			     LastEditedBy)
OUTPUT $action, inserted.*;

--5. �������� ������, ������� �������� ������ ����� bcp out � ��������� ����� bulk insert
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "D:\OTUS\Customers.txt" -T -w -t, -S LAPTOP-CEH70D4D\SQL2017'

--������� ������� ��� �������
SELECT *
INTO Sales.Customers_Test
FROM Sales.Customers
WHERE 1=1

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers_test" out  "D:\OTUS\Customers.txt" -T -w -t"TestSeparator" -S LAPTOP-CEH70D4D\SQL2017'