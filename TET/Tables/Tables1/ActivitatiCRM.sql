CREATE TABLE [dbo].[ActivitatiCRM] (
    [idActivitate]   INT            IDENTITY (1, 1) NOT NULL,
    [idSarcina]      INT            NULL,
    [idOportunitate] INT            NULL,
    [idPotential]    INT            NULL,
    [marca]          VARCHAR (20)   NULL,
    [data]           DATETIME       DEFAULT (getdate()) NULL,
    [termen]         DATETIME       NULL,
    [tip_activitate] VARCHAR (100)  NULL,
    [note]           VARCHAR (2000) NULL,
    [utilizator]     VARCHAR (200)  NULL,
    [detalii]        XML            NULL,
    PRIMARY KEY CLUSTERED ([idActivitate] ASC)
);


GO

create  trigger tr_ActualizareSarcina on ActivitatiCRM for insert,update
as

	update s
		set s.stare='L' 
	from SarciniCRM s
	JOIN inserted i on s.idSarcina=i.idSarcina and s.stare='N'
