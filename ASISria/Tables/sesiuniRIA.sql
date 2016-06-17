CREATE TABLE [dbo].[sesiuniRIA] (
    [token]                VARCHAR (25) NOT NULL,
    [BD]                   VARCHAR (40) NULL,
    [utilizator]           VARCHAR (40) NOT NULL,
    [ip]                   VARCHAR (40) NULL,
    [mac]                  VARCHAR (50) NULL,
    [datai]                VARCHAR (40) NULL,
    [connectionStringName] VARCHAR (15) NULL,
    [activitate]           DATETIME     NULL,
    [maxInactivitate]      DATETIME     NULL,
    CONSTRAINT [PK_sesiuniRIA] PRIMARY KEY CLUSTERED ([token] ASC)
);


GO

CREATE TRIGGER tr_LogUtilizatori ON sesiuniRIA FOR INSERT, DELETE AS
BEGIN
	SET NOCOUNT ON;

	select * into #logutilizatori
	from (select 'I' tip, * from inserted union all select 'D' tip, * from deleted) c
	
	if exists (select * from sysobjects where name ='LogUtilizatoriSP' )
		exec LogUtilizatoriSP		

	INSERT INTO logUtilizatori (token, utilizator, BD, data, tip)
	SELECT token, utilizator, BD, GETDATE(), 'I'
	FROM inserted

	INSERT INTO logUtilizatori (token, utilizator, BD, data, tip)
	SELECT token, utilizator, BD, GETDATE(), 'E'
	FROM deleted
END

