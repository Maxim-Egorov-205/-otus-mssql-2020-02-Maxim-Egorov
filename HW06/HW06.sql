--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
--Вывести:
-- Год продажи
-- Месяц продажи
-- Средняя цена за месяц по всем товарам
-- Общая сумма продаж
SELECT YEAR(i.InvoiceDate) AS y,
	   MONTH(i.InvoiceDate) AS m,
	   AVG(s.UnitPrice) AS avg_price,
	   SUM(il.Quantity*il.UnitPrice) AS sum_realize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN Warehouse.StockItems s
			ON s.StockItemID = il.StockItemID
GROUP BY YEAR(i.InvoiceDate),
	     MONTH(i.InvoiceDate)
ORDER BY y,
         m

--1.1
--Написать запросы 1-3 так, чтобы если в каком-то месяце не было продаж,
--то этот месяц также отображался бы в результатах, но там были нули.

WITH Cte_YM AS						--рекурсивная CTE со всеми годами, меяцами                                     
(
	SELECT  DISTINCT YEAR(i.InvoiceDate) AS y, 1 AS m  --берем из базы все доступные годы, т.к. неизвестно сколько их может быть
	FROM Sales.Invoices i
	UNION ALL
	SELECT y, m+1
	FROM Cte_YM c 
	WHERE c.m<12 --количество месяцев в в году знаем, задаем 12 
),

Cte_DATA AS	     --сами данные  по продажам                                         
(
	SELECT YEAR(i.InvoiceDate) AS y,
		   MONTH(i.InvoiceDate) AS m,
		   AVG(s.UnitPrice) AS avg_price,
		   SUM(il.Quantity*il.UnitPrice) AS sum_realize
	FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
	GROUP BY YEAR(i.InvoiceDate),
			 MONTH(i.InvoiceDate)
)

SELECT ym.y,
       ym.m,
	   ISNULL(d.avg_price,0) AS avg_price,
	   ISNULL(d.sum_realize,0) AS sum_realize
FROM Cte_YM ym
	LEFT JOIN Cte_DATA d 
		ON ym.y=d.y AND ym.m=d.m
ORDER BY ym.y,
	     ym.m

--2. Отобразить все месяцы, где общая сумма продаж превысила 10 000
--Вывести:
--* Год продажи
--* Месяц продажи
--* Общая сумма продаж
--Продажи смотреть в таблице Sales.Invoices и связанных таблицах.

SELECT YEAR(i.InvoiceDate) AS y,
       MONTH(i.InvoiceDate) AS m,         
       DATENAME(MONTH,i.InvoiceDate) +' '+ CAST(YEAR(i.InvoiceDate) as varchar(10)) AS my,
	   SUM(il.Quantity*il.UnitPrice) AS sum_realize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN Warehouse.StockItems s
			ON s.StockItemID = il.StockItemID
GROUP BY DATENAME(MONTH,i.InvoiceDate) +' '+ CAST(YEAR(i.InvoiceDate) as varchar(10)),	     
		 YEAR(i.InvoiceDate),
		 MONTH(i.InvoiceDate)
HAVING SUM(il.Quantity*il.UnitPrice)>10000
ORDER BY y,
	     m
--2.1 Написать запросы 1-3 так, чтобы если в каком-то месяце не было продаж,
--   то этот месяц также отображался бы в результатах, но там были нули.

WITH Cte_YM AS						--рекурсивная CTE со всеми годами, меяцами                                     
(
	SELECT  DISTINCT YEAR(i.InvoiceDate) AS y, 1 AS m  --берем из базы все доступные годы, т.к. неизвестно сколько их может быть
	FROM Sales.Invoices i
	UNION ALL
	SELECT y, m+1
	FROM Cte_YM c 
	WHERE c.m<12 --количество месяцев в в году знаем, задаем 12 
),

Cte_DATA AS	     --сами данные  по продажам  
(
	SELECT YEAR(i.InvoiceDate) AS y,
		   MONTH(i.InvoiceDate) AS m,         
		   DATENAME(MONTH,i.InvoiceDate) +' '+ CAST(YEAR(i.InvoiceDate) as varchar(10)) AS my,
		   SUM(il.Quantity*il.UnitPrice) AS sum_realize
	FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
	GROUP BY DATENAME(MONTH,i.InvoiceDate) +' '+ CAST(YEAR(i.InvoiceDate) as varchar(10)),	     
			 YEAR(i.InvoiceDate),
			 MONTH(i.InvoiceDate)
	HAVING SUM(il.Quantity*il.UnitPrice)>10000
)

SELECT ym.y,
       ym.m,
	   ISNULL(d.sum_realize,0) AS sum_realize
FROM Cte_YM ym
	LEFT JOIN Cte_DATA d 
		ON ym.y=d.y AND ym.m=d.m
ORDER BY ym.y,
	     ym.m
     
/*
3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.
Группировка должна быть по году, месяцу, товару.
Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного
Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(i.InvoiceDate) AS y,
	   MONTH(i.InvoiceDate) AS m, 
	   il.stockitemid,
	   il.[Description] AS StockItem_name,
	   SUM(il.Quantity*il.UnitPrice) AS sum_realize,
	   MIN(i.InvoiceDate) AS DateFirstSale
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN Warehouse.StockItems s
			ON s.StockItemID = il.StockItemID
GROUP BY YEAR(i.InvoiceDate),
	     MONTH(i.InvoiceDate),  
	     il.[Description],
		 il.stockitemid
HAVING SUM(il.Quantity)<50
ORDER BY y,
	     m,
		 StockItem_name

--3.1 Написать запросы 1-3 так, чтобы если в каком-то месяце не было продаж,
--    то этот месяц также отображался бы в результатах, но там были нули.
WITH Cte_YM AS  --рекурсивная CTE со всеми годами, меяцами                                     
(
	SELECT  DISTINCT YEAR(i.InvoiceDate) AS y, 1 AS m  --берем из базы все доступные годы, т.к. неизвестно сколько их может быть
	FROM Sales.Invoices i
	UNION ALL
	SELECT y, m+1
	FROM Cte_YM c 
	WHERE c.m<12 --количество месяцев в в году знаем, задаем 12 
),

Cte_DATA AS	     --сами данные  по продажам  
(
	SELECT YEAR(i.InvoiceDate) AS y,
		   MONTH(i.InvoiceDate) AS m, 
		   il.[Description] AS StockItem_name,
		   SUM(il.Quantity*il.UnitPrice) AS sum_realize,
		   MIN(i.InvoiceDate) AS DateFirstSale
	FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
	GROUP BY YEAR(i.InvoiceDate),
			 MONTH(i.InvoiceDate),  
			 il.[Description],
			 il.stockitemid
	HAVING SUM(il.Quantity)<50
)

SELECT ym.y,
       ym.m,
	   ISNULL(StockItem_name,'') AS StockItem_name,
	   ISNULL(sum_realize,0) AS sum_realize,
	   ISNULL(CONVERT(varchar,DateFirstSale,104),'')  AS DateFirstSale
FROM Cte_YM ym
	LEFT JOIN Cte_DATA d 
		ON ym.y=d.y AND ym.m=d.m
ORDER BY ym.y,
	     ym.m

/*
4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
Дано :
CREATE TABLE dbo.MyEmployees
(
EmployeeID smallint NOT NULL,
FirstName nvarchar(30) NOT NULL,
LastName nvarchar(40) NOT NULL,
Title nvarchar(50) NOT NULL,
DeptID smallint NOT NULL,
ManagerID int NULL,
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC)
);

INSERT INTO dbo.MyEmployees VALUES
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);

Результат вывода рекурсивного CTE:
EmployeeID Name Title EmployeeLevel
1 Ken Sánchez Chief Executive Officer 1
273 | Brian Welcker Vice President of Sales 2
16 | | David Bradley Marketing Manager 3
23 | | | Mary Gibson Marketing Specialist 4
274 | | Stephen Jiang North American Sales Manager 3
276 | | | Linda Mitchell Sales Representative 4
275 | | | Michael Blythe Sales Representative 4
285 | | Syed Abbas Pacific Sales Manager 3
286 | | | Lynn Tsoflias Sales Representative 4
*/

DROP TABLE IF EXISTS dbo.MyEmployees

CREATE TABLE dbo.MyEmployees
(
	EmployeeID smallint NOT NULL,
	FirstName nvarchar(30) NOT NULL,
	LastName nvarchar(40) NOT NULL,
	Title nvarchar(50) NOT NULL,
	DeptID smallint NOT NULL,
	ManagerID int NULL,
	CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC)
);

INSERT INTO dbo.MyEmployees VALUES
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);

WITH CTE_MyEmployees (EmployeeID,FirstName,LastName,Title,ManagerID,EmployeeLevel) AS 
(
	SELECT EmployeeID,
	       FirstName,
		   LastName,
		   Title,
		   ManagerID,
		   1 as EmployeeLevel
	FROM dbo.MyEmployees 
	WHERE ManagerID IS NULL
	UNION ALL
	SELECT e.EmployeeID,
	       e.FirstName,
		   e.LastName,
		   e.Title,
		   e.ManagerID,
		   c.EmployeeLevel+1
	FROM MyEmployees e
		JOIN CTE_MyEmployees c
			ON e.ManagerID=c.EmployeeID
)

SELECT  c.EmployeeID,
        c.FirstName +' '+c.LastName AS Name,
		c.Title,
		c.EmployeeLevel
FROM CTE_MyEmployees c



