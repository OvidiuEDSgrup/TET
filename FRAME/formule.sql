SELECT * FROM OPENQUERY(ASWDEV, '
SELECT [Meniu]
      ,[Tip]
      ,[Subtip]
      ,[Ordine]
      ,[Nume]
      ,[TipObiect]
      ,[DataField]
      ,[LabelField]
      ,[Latime]
      ,[Vizibil]
      ,[Modificabil]
      ,[ProcSQL]
      ,[ListaValori]
      ,[ListaEtichete]
      ,[Initializare]
      ,[Prompt]
      ,[Procesare]
      ,[Tooltip]
      ,[formula]
  FROM [GHITA].[dbo].[webConfigForm] f') f
  where isnull(f.formula,'')<>''
GO


SELECT * FROM OPENQUERY(ASWDEV, '
SELECT [Meniu]
      ,[Tip]
      ,[Subtip]
      ,[InPozitii]
      ,[NumeCol]
      ,[DataField]
      ,[TipObiect]
      ,[Latime]
      ,[Ordine]
      ,[Vizibil]
      ,[modificabil]
      ,[formula]
  FROM [GHITA].[dbo].[webConfigGrid]') f
  where isnull(f.formula,'')<>''
GO


