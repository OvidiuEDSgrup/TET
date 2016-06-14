-- Host: ysovidiu
-- Database: [tet_bk]
-- Table: [dbo].[webconfigform]
INSERT INTO [dbo].[webconfigform] ([DataField],[IdUtilizator],[Initializare],[LabelField],[Latime],[ListaEtichete],[ListaValori],[Meniu],[Modificabil],[Nume],[Ordine],[Procesare],[ProcSQL],[Prompt],[Subtip],[Tip],[TipMacheta],[TipObiect],[Tooltip],[Vizibil]) VALUES (N'@contr_cadru',NULL,NULL,N'@contr_cadru',300,NULL,NULL,N'CO',1,N'Contr. coresp.',30,NULL,N'wACContracte',N'Contract Corespondent',NULL,N'BK',N'D',N'AC',NULL,1)
UPDATE [dbo].[webconfigform] SET [Latime]=100 WHERE [DataField] = N'@discount' AND [IdUtilizator] IS NULL AND [Meniu] = N'CO' AND [Subtip] = N'BK' AND [Tip] = N'BK' AND [TipMacheta] = N'D'
UPDATE [dbo].[webconfigform] SET [Ordine]=20 WHERE [DataField] = N'@explicatii' AND [IdUtilizator] IS NULL AND [Meniu] = N'CO' AND [Subtip] = N'BK' AND [Tip] = N'BK' AND [TipMacheta] = N'D'
UPDATE [dbo].[webconfigform] SET [Latime]=100,[Nume]=N'Disc.supl.2',[Ordine]=14,[Vizibil]=0 WHERE [DataField] = N'@info1' AND [IdUtilizator] IS NULL AND [Meniu] = N'CO' AND [Subtip] = N'BK' AND [Tip] = N'BK' AND [TipMacheta] = N'D'
UPDATE [dbo].[webconfigform] SET [Vizibil]=0 WHERE [DataField] = N'@info2' AND [IdUtilizator] IS NULL AND [Meniu] = N'CO' AND [Subtip] = N'BK' AND [Tip] = N'BK' AND [TipMacheta] = N'D'
UPDATE [dbo].[webconfigform] SET [Latime]=100,[Nume]=N'Disc.supl.3',[Ordine]=18 WHERE [DataField] = N'@info3' AND [IdUtilizator] IS NULL AND [Meniu] = N'CO' AND [Subtip] = N'BK' AND [Tip] = N'BK' AND [TipMacheta] = N'D'
INSERT INTO [dbo].[webconfigform] ([DataField],[IdUtilizator],[Initializare],[LabelField],[Latime],[ListaEtichete],[ListaValori],[Meniu],[Modificabil],[Nume],[Ordine],[Procesare],[ProcSQL],[Prompt],[Subtip],[Tip],[TipMacheta],[TipObiect],[Tooltip],[Vizibil]) VALUES (N'@contr_cadru',NULL,NULL,N'@contr_cadru',300,NULL,NULL,N'KO',1,N'Contr. coresp.',30,NULL,N'wACContracte',N'Contract Corespondent',NULL,N'BK',N'D',N'AC',NULL,1)
