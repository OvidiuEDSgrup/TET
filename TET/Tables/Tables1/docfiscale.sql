CREATE TABLE [dbo].[docfiscale] (
    [Id]           INT            IDENTITY (1, 1) NOT NULL,
    [TipDoc]       CHAR (3)       NOT NULL,
    [Serie]        CHAR (9)       NOT NULL,
    [NumarInf]     INT            NOT NULL,
    [NumarSup]     INT            NOT NULL,
    [UltimulNr]    INT            NOT NULL,
    [SerieInNumar] INT            DEFAULT ((0)) NULL,
    [meniu]        VARCHAR (20)   NULL,
    [subtip]       VARCHAR (2)    NULL,
    [descriere]    VARCHAR (1000) NULL,
    [dela]         DATETIME       DEFAULT ('1901-01-01') NULL,
    [panala]       DATETIME       DEFAULT ('2901-01-01') NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[docfiscale]([Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UnicitateDocF]
    ON [dbo].[docfiscale]([meniu] ASC, [TipDoc] ASC, [subtip] ASC, [Serie] ASC, [NumarInf] ASC);


GO
create  trigger tr_ValidPlaje on docfiscale for update NOT FOR REPLICATION as
/*
	Triggerul asigura "integritatea" plajelor de numere care au fost folosite dupa regula de mai jos
	Partea de "stergere" este asigurata prin contrangerea de FK intre tabele doc.idplaja si docfiscale.id- nu permite stergerea unei plaje din care s-a alocat nr.
*/
begin try	
	/** 
		Inainte sa fie folosit vreun numar din plaja exista posibiltatea de a modificare orice(numarInf, numarSup, serie, serieInNumar, ultimulNumar...)
		Dupa ce au fost date numere din plaja (idplaja existent in doc...) se poate interveni doar asupra ultimului numar
	**/
	IF EXISTS (select 1 from DELETED) and EXISTS (select 1 from INSERTED)
	BEGIN
		IF 
			EXISTS (select 1 from DELETED d join doc on doc.idplaja=d.Id) and
			EXISTS (select 1 from DELETED d JOIN INSERTED i on d.id=i.id and (d.tipDoc<>i.TipDoc OR d.Serie<>i.Serie OR d.NumarInf<>i.NumarInf OR d.NumarSup<> i.NumarSup OR d.SerieInNumar<>i.SerieInNumar))
				RAISERROR ('Nu puteti actualiza plaja deoarece exista documente cu numere atribuite din aceasta plaja!', 16, 1)
	END

	declare @lenNumarPozdoc int, @mesajEroare varchar(1000)
	set @lenNumarPozdoc=(SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id 
			where tbl.name='pozdoc' and clmns.name= 'numar') 
	if exists (select 1 from inserted where TipDoc in ('RM','RS','RC','TE','PP','PF','DF','CM','CI','AP','AS','AI','AF','AE','AC') 
		and len((case when SerieInNumar=1 then rtrim(Serie) else '' end)+ltrim(str(NumarSup)))>@lenNumarPozdoc)
	begin	
		set @mesajEroare='Numarul de document pe tabela pozdoc trebuie sa aiba maxim '+convert(varchar(3),@lenNumarPozdoc)+' caractere!'
		RAISERROR (@mesajEroare, 16, 1)
	end

end try
begin catch	
	ROLLBACK TRANSACTION
	declare @mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() +' (tr_ValidPlaje)'
	raiserror(@mesaj, 11, 1)
end catch
