--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--1.1.через вложенный запрос
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
WHERE  NOT EXISTS (SELECT o.SalespersonPersonID  FROM SALES.ORDERS o WHERE p.PersonID=o.SalespersonPersonID)
   AND p.IsSalesperson=1 --продажники

--1.2.через WITH (для производных таблиц)
WITH CteSalesPersonOrders AS                                            --все id продажников, которые создавали заказы
(
	SELECT  DISTINCT SalespersonPersonID
	FROM Sales.Orders
)
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
	LEFT JOIN CteSalesPersonOrders c
		ON p.PersonID=c.SalespersonPersonID	
WHERE c.SalespersonPersonID IS NULL
	AND p.IsSalesperson=1 --продажники

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.
--2.1.
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
WHERE S.UnitPrice IN (SELECT TOP 1 UnitPrice FROM [Warehouse].[StockItems]  ORDER BY UnitPrice ASC)

--2.2.
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
WHERE S.UnitPrice IN (SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems])

--2.3.через WITH (для производных таблиц)
WITH CteMinUnitPrice AS              
(
	SELECT MIN(UnitPrice) AS UnitPrice
	FROM [Warehouse].[StockItems]
)
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
JOIN CteMinUnitPrice c
	ON s.UnitPrice=c.UnitPrice

--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных
--платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--3.1 c CTE
WITH CteMaxTransactionAmount AS              --5 максимальных платежей  клиентов 
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT c.CustomerID,
			    c.CustomerName
FROM Sales.Customers c
	JOIN CteMaxTransactionAmount ct ON c.CustomerID=ct.CustomerID

--3.2 Вариант с IN
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN 
	(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
	)

--3.3 вариант с cte,exists
WITH CteMaxTransactionAmount AS             
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
)
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE EXISTS (SELECT CustomerID FROM CteMaxTransactionAmount ct where ct.CustomerID=c.CustomerID) 

--4. Выберите города (ид и название), в которые были доставлены товары,
--входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов
--4.1. with
WITH CteMaxUnitPrice AS                            
(
	SELECT TOP 3 StockItemID
	FROM [Warehouse].[StockItems]
	ORDER BY UnitPrice DESC
)
SELECT DISTINCT ct.CityID,
		        ct.CityName,
		        p.FullName	 
FROM sales.Invoices i
	JOIN Sales.InvoiceLines il
		ON i.InvoiceID=il.InvoiceID              
	JOIN CteMaxUnitPrice m
		ON il.StockItemID = m.StockItemID     
	JOIN Sales.Customers c
		ON  i.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId  	    
    JOIN Application.People	p
		ON i.PackedByPersonID=p.PersonID    
		 		 	                                    											
--4.2. подзапросом
SELECT DISTINCT ct.CityID,
		        ct.CityName,
		        p.FullName	 
FROM sales.Invoices i
	JOIN Sales.InvoiceLines il
		ON i.InvoiceID=il.InvoiceID                
	JOIN Sales.Customers c
		ON  i.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId  	    
    JOIN Application.People	p
		ON i.PackedByPersonID=p.PersonID     	                                   											
WHERE EXISTS 
	(
		SELECT m.StockItemID
		FROM (
				SELECT TOP 3 StockItemID
				FROM [Warehouse].[StockItems]
				 ORDER BY UnitPrice DESC
			  ) m
		WHERE il.StockItemID = m.StockItemID
	)

--5. Объясните, что делает и оптимизируйте запрос:
--Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации.
SELECT Invoices.InvoiceID,
	   Invoices.InvoiceDate,
		(
		  SELECT People.FullName
		  FROM Application.People
		  WHERE people.PersonID = Invoices.SalespersonPersonID
		) AS SalesPersonName,
		SalesTotals.TotalSumm AS TotalSummByInvoice,
		( SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)                               -- количество выбранное со склада * цена единицы измерения
		  FROM Sales.OrderLines
		  WHERE OrderLines.OrderId = (SELECT Orders.OrderId                                        -- ид заказа, для которых были оплачены счета и заказ был скомплектован
									  FROM Sales.Orders
									  WHERE Orders.PickingCompletedWhen IS NOT NULL                --дата комплектации заказа заполнена
										AND Orders.OrderId = Invoices.OrderId)
		) AS TotalSummForPickedItems
FROM Sales.Invoices
	JOIN (
		  SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		  FROM Sales.InvoiceLines
		  GROUP BY InvoiceId
		  HAVING SUM(Quantity*UnitPrice) > 27000
		  ) AS SalesTotals	
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

--Объяснение:
-- для счетов, сумма которых больше 27 000 долларов
-- вывести id счета
-- дату счета
-- имя продавца, оформившего счет
-- итоговую сумму счета
-- итоговую сумму каждого соответствующего счету скомплектованного заказа (дата комплектации заполнена - не нулл)

--АНАЛИЗ ПЛАНА ЗАПРОСА (считаем ветки сверху вниз, всего 5 веток)
--1. index scan таблицы People, стоимость невысокая
		--соответствует подзапросу 
		--(
		--  SELECT People.FullName
		--  FROM Application.People
		--  WHERE people.PersonID = Invoices.SalespersonPersonID
		--) AS SalesPersonName,

--2. index scan таблицы InvoicesLines стоимость невысокая, 
          --соответствует подзапросу 
		  --SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		  --FROM Sales.InvoiceLines
		  --GROUP BY InvoiceId
		  --HAVING SUM(Quantity*UnitPrice) > 27000

--3. index scan таблицы Invoices, стоимость невысокая , джоин Invoices с подзапросом из п.2.
--FROM Sales.Invoices
--	JOIN (
--		  SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
--		  FROM Sales.InvoiceLines
--		  GROUP BY InvoiceId
--		  HAVING SUM(Quantity*UnitPrice) > 27000
--		  ) AS SalesTotals	
--		ON Invoices.InvoiceID = SalesTotals.InvoiceID


--4 и 5-я ветка.
	    --самая дорогая операция в 4-й ветке - index scan таблицы OrderLines
		--( SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)                               -- количество выбранное со склада * цена единицы измерения
		--  FROM Sales.OrderLines
		--  WHERE OrderLines.OrderId = (SELECT Orders.OrderId                                        -- ид заказа, для которых были оплачены счета и заказ был скомплектован
		--							  FROM Sales.Orders
		--							  WHERE Orders.PickingCompletedWhen IS NOT NULL                   --дата комплектации заказа заполнена
		--								AND Orders.OrderId = Invoices.OrderId)
		--) AS TotalSummForPickedItems


--ход рассуждений по поводу оптимизации:
--проблемное место - дорогой indexscan 4-й ветки, может быть решено добавлением некластерного индекса на таблицу OrderLines на все поля, указанные в плане запроса.
--но создавать индекс для каждого запроса - места на диске не хватит, поэтому надо попробовать переписать запрос,
--т.к. основная проблема, на мой взгляд - плохая читабельность и частое использование связанных подзапросов

--оптимизированный запрос
--Подзапросы были вынесены в отдельные CTE (как для удобства чтения, так и для избавления от подзапросов)
--запрос был переписан так, чтобы не было связанных подзапросов, выдающих набор данных для каждой строки основной таблицы
--хотя считается, что  SQL server последних версий с этим справляется, я решил лишний раз не рисковать

--До оптимизации стоимость была около 9
--После оптимизации - около 3,8

WITH CteSalesTotals AS -- все счета, сумма которых больше 27 000 долларов
(
	SELECT il.InvoiceId,
	       SUM(il.Quantity*il.UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines il
	GROUP BY il.InvoiceId
	HAVING SUM(il.Quantity*il.UnitPrice) > 27000
),
CteSalesPersonName AS --все продавцы оформившие счета больше 27000
(
	SELECT i.InvoiceID,
		   p.PersonID,
		   p.FullName as SalesPersonName	 
	FROM Sales.Invoices i
		JOIN CteSalesTotals ct1 
			ON i.InvoiceID=ct1.InvoiceID
		JOIN Application.people p 
			ON p.PersonID = i.SalespersonPersonID
)
SELECT i.InvoiceID,
	   i.InvoiceDate,
	   ct2.SalesPersonName,
	   ct1.TotalSumm,
	   SUM(ol.PickedQuantity*ol.UnitPrice)   AS TotalSummForPickedItems	
FROM Sales.Invoices i
	JOIN CteSalesTotals ct1
		 ON i.InvoiceID =ct1.InvoiceID
	JOIN CteSalesPersonName ct2 
		ON i.InvoiceID=ct2.invoiceid
	JOIN Sales.OrderLines ol 
		ON ol.OrderID=i.OrderID
GROUP BY i.InvoiceID,
	     i.InvoiceDate,
	     i.OrderID,
	     ct2.SalesPersonName,
	     ct1.TotalSumm
ORDER BY SUM(ol.PickedQuantity*ol.UnitPrice)  DESC