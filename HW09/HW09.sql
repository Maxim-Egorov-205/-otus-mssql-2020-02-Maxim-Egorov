--1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
--Название клиента
--МесяцГод Количество покупок
--Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
--имя клиента нужно поменять так чтобы осталось только уточнение
--например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
--дата должна иметь формат dd.mm.yyyy например 25.12.2019
--Например, как должны выглядеть результаты:
--InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
--01.01.2013 3 1 4 2 2
--01.02.2013 7 3 4 2 1

SELECT InvoiceMonth, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT],[Jessie, ND]
FROM
(
	SELECT SUBSTRING(c.CustomerName,CHARINDEX('(',c.CustomerName)+1,CHARINDEX(')',c.CustomerName)-CHARINDEX('(',c.CustomerName)-1) AS ShortName,
		   CONVERT(varchar,dateadd(day, - datepart(day, i.InvoiceDate) + 1, convert(date, i.InvoiceDate)),104) AS InvoiceMonth, 
		   il.QuantitY AS Qtty
	FROM sales.Customers c 
			JOIN Sales.Invoices i
				ON i.CustomerID=c.CustomerID
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
	WHERE c.CustomerID BETWEEN 2 AND 6
) AS SourceTable
PIVOT (SUM(Qtty)
FOR ShortName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT],[Jessie, ND]))
as PVT
ORDER BY InvoiceMonth

--2. Для всех клиентов с именем, в котором есть Tailspin Toys
--вывести все адреса, которые есть в таблице, в одной колонке
--Пример результатов
--CustomerName AddressLine
--Tailspin Toys (Head Office) Shop 38
--Tailspin Toys (Head Office) 1877 Mittal Road
--Tailspin Toys (Head Office) PO Box 8975
--Tailspin Toys (Head Office) Ribeiroville

SELECT CustomerName,
       Addr
FROM (
		SELECT c.CustomerName,
			   c.DeliveryAddressLine1,
			   c.DeliveryAddressLine2,
			   c.PostalAddressLine1,
			   c.PostalAddressLine2
		FROM sales.Customers c
		WHERE c.CustomerName LIKE '%Tailspin Toys%'
	 ) AS SourceTable
UNPIVOT (Addr For Colnname IN (DeliveryAddressLine1,DeliveryAddressLine2,PostalAddressLine1,PostalAddressLine2)) AS Unpvt
ORDER BY CustomerName

--3. В таблице стран есть поля с кодом страны цифровым и буквенным
--сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код

SELECT CountryID,
	   CountryName,
	   Code
FROM (
		SELECT c.CountryID,
			   c.CountryName,
			   CAST(c.IsoAlpha3Code AS nvarchar) AS IsoAlpha3Code,
			   CAST(c.IsoNumericCode AS nvarchar) AS IsoNumericCode 
		FROM 
		[Application].[Countries] c
	 ) AS SourceTable
UNPIVOT (Code For Colnname IN (IsoAlpha3Code,IsoNumericCode)) AS Unpvt
ORDER BY CountryID

--4. Перепишите ДЗ из оконных функций через CROSS APPLY
--Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки

---запрос через cross apply
SELECT c.CustomerID,
	   c.CustomerName,
	   CR.UnitPrice,
	   CR.InvoiceDate	   
FROM sales.Customers c  
		CROSS APPLY (
					  SELECT TOP 2 il.UnitPrice,
							      max(i.InvoiceDate) AS InvoiceDate  
					  FROM Sales.Invoices i
							join sales.InvoiceLines il 
								ON il.InvoiceID = i.InvoiceID 
					  WHERE c.CustomerID=i.CustomerID
					  GROUP BY il.UnitPrice
					  ORDER BY il.UnitPrice DESC
		             ) AS CR
		
--Для сравнения запрос через оконную функцию (гораздо быстрее, как побороть key lookup без создания покрывающего индекса, не понятно)	
SELECT CustomerID,
	   CustomerName,
	   UnitPrice,
	   InvoiceDate
FROM (
	   SELECT c.CustomerID,
	   c.CustomerName,
	   s.StockItemID,
	   il.UnitPrice,
	   max(i.InvoiceDate) AS InvoiceDate,
	   row_number () over (partition by c.CustomerID order by il.UnitPrice desc) AS rown_price	   
	   FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
			JOIN sales.Customers c 
			    ON i.CustomerID=c.CustomerID
group by c.CustomerID,
	     c.CustomerName,
	     s.StockItemID,
	     il.UnitPrice				
		 ) AS x
WHERE rown_price<=2

--5. Code review (опционально). Запрос приложен в материалы Hometask_code_review.sql.

--что делает запрос ?
	--запрос из временной таблицы со всеми версиями файлов выводит те файлы , которые не были удалены, и не были восстановлены
	--т.е. по логике, он должен выводить только актуальные  версии файлов
	-- но вероятнее всего, это проверочный скрипт на согласованность БД, т.к. для актуальности можно добавить и использоватья некий признак, битовое поле [Actual] 0 или 1

SELECT     T.FolderId,
		   T.FileVersionId,
		   T.FileId		
	FROM dbo.vwFolderHistoryRemove FHR                     --вьюха, история удаления папок
	CROSS APPLY (SELECT TOP 1   FileVersionId,
								FileId,
								FolderId,
								DirId
		     	FROM #FileVersions V                       -- временная таблица со всеми версиями файлов
				WHERE RowNum = 1
					  AND DirVersionId <= FHR.DirVersionId -- непонятно, что по топ1 выведет cross apply, т.к. никаких привязок нет, например по DirId и FolderId
				ORDER BY V.DirVersionId DESC) T				
	WHERE FHR.[FolderId] = T.FolderId                      -- это условие можно было бы включть в cross apply
	AND FHR.DirId = T.DirId								   -- это условие можно было бы включть в cross apply		
	AND EXISTS (SELECT 1 FROM #FileVersions V WHERE V.DirVersionId <= FHR.DirVersionId) --Это условие можно было бы убрать, т.к. уже есть в cross apply
	AND NOT EXISTS (   
			SELECT 1
			FROM dbo.vwFileHistoryRemove DFHR              -- вьюха с историей удаления, проверка, что файлы не удалены         
			WHERE DFHR.FileId = T.FileId		         
				AND DFHR.[FolderId] = T.FolderId	     
				AND DFHR.DirVersionId = FHR.DirVersionId 									
			AND NOT EXISTS (
					SELECT 1                              																													
					FROM dbo.vwFileHistoryRestore DFHRes   -- вьюха с историей восстановления файлов, проверка что файлы не восстановлены
					WHERE DFHRes.[FolderId] = T.FolderId                              
						AND DFHRes.FileId = T.FileId
						AND DFHRes.PreviousFileVersionId = DFHR.FileVersionId
					)
			)
--Чем можно заменить CROSS APPLY - можно ли использовать другую стратегию выборки\запроса?
--в принципе чем угодно, т.к. для каждой строки запроса выводится только одна строка из cross apply