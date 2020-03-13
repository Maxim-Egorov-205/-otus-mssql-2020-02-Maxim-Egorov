--Опциональная часть:
--В материалах к вебинару есть файл HT_reviewBigCTE.sql - прочтите этот запрос и напишите что он должен вернуть и в чем его смысл, можно если есть идеи по улучшению тоже их включить.

--Ответ
--на вход перед началом выплнениня запроса должны быть объявлены переменные
      @DFBatchSize              -- размер пакета   
	  @vfId                     -- id виртуальной папки
	  @vfOwnerId                -- владелец виртуальной папки
	  @maxDFKeepDate            -- максимальная дата хранения?
	  @keepDeletedFromDate      -- хранить после удаления

--временная таблица #companyCustomRules T
--поля таблицы
--DeletedFileYears,  удаленные файлы за год        
--DeletedFileMonths, удаленные файлы за месяц
--DeletedFileDays    удаленные файлы за день
--CustomRuleId       id пользовательского правила  
--Priority           приоритет
--RuleType           тип правила
--RuleCondition      условие срабатывания правила
--RuleItemFileType   правило элемента типа файла ???
--RuleItemFileMask   правило элемента маски файла 


--постоянная таблица dbo.UserFile DF -- файлы пользователя
--FolderId    -- id папки
--UserFileId  -- id файла пользователя
--ExtensionId -- id расширения файла  

--постоянная таблица dbo.UserFileExtension dfe --справочник расширений пользовательских файлов 
--dfe.[ExtensionId] --  id расширений пользовательских файлов
--dfe.[FileTypeId]  --  id типа файла

--функция
--dbo.RegExMatch(DF.Name, T.RuleItemFileMask) 

dbo.UserFile DF with(nolock) on dDF.FolderId = df.FolderId and dDF.UserFileId = Df.UserFileId


--используется вьюха dbo.vwUserFileInActive  

--не вернет ничего, создаст только две cte

--в чем смысл запроса?
--первое cte



-- cte1 по id виртуальной папки выводит некие аттрибуты виртуальной папки -- с файлы, пользователи
-- где фактическая дата удаления меньше максимальной даты хранения, т.е. видимо файлы в состоянии "удален" но еще хранящиеся в условной "корзине".

WITH cteDeletedDF as
(
SELECT top (@DFBatchSize)                                    -- размер пакета
		df.UserFileId,                                       -- id поля пользователя
		@vfId as VirtualFolderId,                            -- id виртуальной папки
		@vfOwnerId as OwnerId,                               -- владелец виртуальной папаки
		df.UserFileVersionId,                                -- id версии файла пользователя 
		df.FileId,                                           -- id поля 
		df.[Length],                                         -- длина (чего - не понятно)
		df.EffectiveDateRemovedUtc as lastDeleteDate,        -- последняя фактическая дата удаления в формате utc
		@vfFolderId as FolderId                              -- id папки
 FROM dbo.vwUserFileInActive df with(nolock)                    -- вьюха
  WHERE df.[FolderId] = @vfFolderId                          -- id виртуальной папки 
	AND df.EffectiveDateRemovedUtc < @maxDFKeepDate          -- фактическая дата удаления < макс дата хранения
),



cteDeletedDFMatchedRules
as
(
SELECT ROW_NUMBER() over(partition by DF.UserFileId order by T.Priority) rn,
		DATEADD(YEAR, -t.DeletedFileYears,
				DATEADD(MONTH, -t.DeletedFileMonths,
						DATEADD(DAY, -t.DeletedFileDays , @keepDeletedFromDate))) customRuleKeepDate,
		T.DeletedFileDays as customDeletedDays,
		T.DeletedFileMonths as customDeletedMonths,
		T.DeletedFileYears as customDeletedYears,
		T.CustomRuleId,                   
		dDf.UserFileId,               -- id пользовательского файла
		dDF.FolderId as FolderId      -- id папки

FROM cteDeletedDF dDF

INNER JOIN dbo.UserFile DF with(nolock) on dDF.FolderId = df.FolderId and dDF.UserFileId = Df.UserFileId
LEFT JOIN dbo.UserFileExtension dfe with(nolock) on df.[ExtensionId] = dfe.[ExtensionId]

CROSS JOIN #companyCustomRules T

WHERE
  (
	EXISTS
		(
		SELECT TOP 1
				1 as id
		 where T.RuleType = 0
			and T.RuleCondition = 0
			and T.RuleItemFileType = dfe.[FileTypeId]

		 union all

		SELECT TOP 1
				1
		 where T.RuleType = 0
			and T.RuleCondition = 1
			and T.RuleItemFileType <> dfe.[FileTypeId]

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 0
			and DF.Name = T.RuleItemFileMask

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 4
			and DF.Name like  case T.RuleCondition
							  when 4
							  then '%' + T.RuleItemFileMask + '%' --never will be indexed
							  when 3
							  then '%' + T.RuleItemFileMask --never will be indexed
							  when 2
							  then T.RuleItemFileMask + '%' --may be indexed
							 end

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 5
			and dbo.RegExMatch(DF.Name, T.RuleItemFileMask) = 1 --never will be indexed

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 2
			and T.RuleCondition = 6
			and DF.[Length] > T.RuleItemFileSize

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 2
			and T.RuleCondition = 7
			and DF.[Length] < T.RuleItemFileSize

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 3
			and T.RuleCondition = 0
			and dDF.VirtualFolderId = T.RuleItemVirtualFolderId

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 3
			and T.RuleCondition = 8
			and T.RuleItemVirtualFolderOwnerId = dDf.OwnerId
		)
  )
)