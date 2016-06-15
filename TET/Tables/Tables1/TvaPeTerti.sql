CREATE TABLE [dbo].[TvaPeTerti] (
    [idTvaPeTert] INT          IDENTITY (1, 1) NOT NULL,
    [tipf]        CHAR (1)     NULL,
    [Tert]        VARCHAR (20) NULL,
    [dela]        DATETIME     NOT NULL,
    [tip_tva]     CHAR (1)     NOT NULL,
    [factura]     VARCHAR (20) NULL,
    CHECK ([tip_tva]='I' OR [tip_tva]='N' OR [tip_tva]='P')
);


GO
CREATE UNIQUE CLUSTERED INDEX [pTvaPeTerti]
    ON [dbo].[TvaPeTerti]([tipf] ASC, [Tert] ASC, [factura] ASC, [dela] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [kTvaPeTerti]
    ON [dbo].[TvaPeTerti]([idTvaPeTert] ASC);


GO
/*
	Pentru a evita generarea de necorelatii triggerul nu permite stergerea liniilor legate de TERTI (la facturi se pot sterge) din TvaPeTerti
	Orice modificare a tipului de TVA din dreptul unui tert se realizeaza prin adaugarea unei inregistrari
*/
create  trigger tr_validTVAPeTerti on TVAPeTerti for update,delete NOT FOR REPLICATION as
begin try	
	
	IF EXISTS (select 1 from deleted where factura IS NULL)
		raiserror('Nu este permisa stergerea! Pentru a modifica tipul de TVA se va introduce o noua inregistrare.',16,1)
end try
begin catch	
	ROLLBACK TRANSACTION
	declare @mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() +' (tr_validTVAPeTerti)'
	raiserror(@mesaj, 11, 1)
end catch
