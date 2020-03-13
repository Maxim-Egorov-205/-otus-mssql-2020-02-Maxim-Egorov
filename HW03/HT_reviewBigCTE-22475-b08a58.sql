--������������ �����:
--� ���������� � �������� ���� ���� HT_reviewBigCTE.sql - �������� ���� ������ � �������� ��� �� ������ ������� � � ��� ��� �����, ����� ���� ���� ���� �� ��������� ���� �� ��������.

--�����
--�� ���� ����� ������� ���������� ������� ������ ���� ��������� ����������
      @DFBatchSize              -- ������ ������   
	  @vfId                     -- id ����������� �����
	  @vfOwnerId                -- �������� ����������� �����
	  @maxDFKeepDate            -- ������������ ���� ��������?
	  @keepDeletedFromDate      -- ������� ����� ��������

--��������� ������� #companyCustomRules T
--���� �������
--DeletedFileYears,  ��������� ����� �� ���        
--DeletedFileMonths, ��������� ����� �� �����
--DeletedFileDays    ��������� ����� �� ����
--CustomRuleId       id ����������������� �������  
--Priority           ���������
--RuleType           ��� �������
--RuleCondition      ������� ������������ �������
--RuleItemFileType   ������� �������� ���� ����� ???
--RuleItemFileMask   ������� �������� ����� ����� 


--���������� ������� dbo.UserFile DF -- ����� ������������
--FolderId    -- id �����
--UserFileId  -- id ����� ������������
--ExtensionId -- id ���������� �����  

--���������� ������� dbo.UserFileExtension dfe --���������� ���������� ���������������� ������ 
--dfe.[ExtensionId] --  id ���������� ���������������� ������
--dfe.[FileTypeId]  --  id ���� �����

--�������
--dbo.RegExMatch(DF.Name, T.RuleItemFileMask) 

dbo.UserFile DF with(nolock) on dDF.FolderId = df.FolderId and dDF.UserFileId = Df.UserFileId


--������������ ����� dbo.vwUserFileInActive  

--�� ������ ������, ������� ������ ��� cte

--� ��� ����� �������?
--������ cte



-- cte1 �� id ����������� ����� ������� ����� ��������� ����������� ����� -- � �����, ������������
-- ��� ����������� ���� �������� ������ ������������ ���� ��������, �.�. ������ ����� � ��������� "������" �� ��� ���������� � �������� "�������".

WITH cteDeletedDF as
(
SELECT top (@DFBatchSize)                                    -- ������ ������
		df.UserFileId,                                       -- id ���� ������������
		@vfId as VirtualFolderId,                            -- id ����������� �����
		@vfOwnerId as OwnerId,                               -- �������� ����������� ������
		df.UserFileVersionId,                                -- id ������ ����� ������������ 
		df.FileId,                                           -- id ���� 
		df.[Length],                                         -- ����� (���� - �� �������)
		df.EffectiveDateRemovedUtc as lastDeleteDate,        -- ��������� ����������� ���� �������� � ������� utc
		@vfFolderId as FolderId                              -- id �����
 FROM dbo.vwUserFileInActive df with(nolock)                    -- �����
  WHERE df.[FolderId] = @vfFolderId                          -- id ����������� ����� 
	AND df.EffectiveDateRemovedUtc < @maxDFKeepDate          -- ����������� ���� �������� < ���� ���� ��������
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
		dDf.UserFileId,               -- id ����������������� �����
		dDF.FolderId as FolderId      -- id �����

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