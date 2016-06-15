CREATE TABLE [dbo].[SarciniCRM] (
    [idSarcina]      INT           IDENTITY (1, 1) NOT NULL,
    [idSesizare]     INT           NULL,
    [idPotential]    INT           NULL,
    [idOportunitate] INT           NULL,
    [tip_sarcina]    VARCHAR (100) NULL,
    [marca]          VARCHAR (20)  NULL,
    [descriere]      VARCHAR (200) NULL,
    [termen]         DATETIME      NULL,
    [prioritate]     INT           NULL,
    [utilizator]     VARCHAR (100) NULL,
    [stare]          VARCHAR (20)  NULL,
    [data]           DATETIME      DEFAULT (getdate()) NULL,
    [detalii]        XML           NULL,
    PRIMARY KEY CLUSTERED ([idSarcina] ASC)
);


GO

create  trigger tr_ActualizareSesizare on SarciniCRM for insert,update
as

	update s
		set s.stare='L' 
	from SesizariCRM s
	JOIN inserted i on s.idSesizare=i.idSesizare and s.stare='N'
