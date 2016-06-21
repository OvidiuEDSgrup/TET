CREATE TABLE [dbo].[Table1]
(
	[IdPozDoc] INT NOT NULL PRIMARY KEY, 
	subunit varchar(9),
    [furnizor] VARCHAR(13) NULL, 
    [numar_NC] VARCHAR(8) NULL, 
    [data] DATETIME2(0) NULL, 
    [cod] VARCHAR(20) NULL, 
    [cantitate] DECIMAL(12, 3) NULL, 
    [pret] DECIMAL(15, 5) NULL, 
    [pret_valuta] DECIMAL(15, 5) NULL
)
