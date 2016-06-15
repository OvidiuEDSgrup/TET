CREATE TABLE [dbo].[necesaraprov] (
    [Numar]         CHAR (8)       NOT NULL,
    [Data]          DATETIME       NOT NULL,
    [Numar_pozitie] INT            NOT NULL,
    [Gestiune]      CHAR (9)       NOT NULL,
    [Cod]           CHAR (20)      NOT NULL,
    [Cantitate]     FLOAT (53)     NOT NULL,
    [Stare]         CHAR (1)       NOT NULL,
    [Loc_de_munca]  CHAR (9)       NOT NULL,
    [Comanda]       CHAR (13)      NOT NULL,
    [Numar_fisa]    CHAR (8)       NOT NULL,
    [Utilizator]    CHAR (10)      NOT NULL,
    [Data_operarii] DATETIME       NOT NULL,
    [Ora_operarii]  CHAR (6)       NOT NULL,
    [detalii]       XML            NULL,
    [explicatii]    VARCHAR (8000) NULL,
    [termen]        DATETIME       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[necesaraprov]([Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[necesaraprov]([Numar] ASC, [Data] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Stare]
    ON [dbo].[necesaraprov]([Data] ASC, [Stare] ASC);


GO
CREATE NONCLUSTERED INDEX [Fisa]
    ON [dbo].[necesaraprov]([Comanda] ASC, [Numar_fisa] ASC, [Cod] ASC);


GO
--***
create trigger yso_tr_actualizeazaRN on necesaraprov after insert,update,delete
as
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	
	select numar=isnull(i.Numar,d.Numar), data=isnull(i.Data,d.data), numar_pozitie=isnull(i.Numar_pozitie,d.numar_pozitie)
		, cantitate=coalesce(i.Cantitate,d.cantitate), stare=coalesce(i.Stare*10,-10)
	into #NAmodStare 
	from inserted i full join deleted d on d.Numar=i.Numar and d.Data=i.Data and d.Numar_pozitie=i.Numar_pozitie 
	where (coalesce(d.Stare*10,-15)<>coalesce(i.Stare*10,-10) or isnull(d.Cantitate,0)<>isnull(i.Cantitate,0))

	create table #RNmodStare (idContract int not null)
/*
	select p.idContract,*, --*/ update p set
		starePoz=n.stare
	output inserted.idcontract into #RNmodStare 
	from PozContracte p join Contracte c on c.idContract=p.idContract
		join #NAmodStare n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
	where isnull(p.starePoz,-15)<>n.Stare or p.cantitate<>n.Cantitate
	
	declare @p xml
	set @p=(select distinct r.idContract from #RNmodStare r for xml raw, root('Date'), type)
	exec updateStareSetContracte null,@p	
	
	select numar=isnull(i.Numar,d.Numar), data=isnull(i.Data,d.data), numar_pozitie=isnull(i.Numar_pozitie,d.numar_pozitie)
		, cantitate=coalesce(i.Cantitate,d.cantitate)
		, termen=coalesce(i.termen,d.termen), explicatii=coalesce(i.explicatii,d.explicatii)
	into #NAmodDate 
	from inserted i left join deleted d on d.Numar=i.Numar and d.Data=i.Data and d.Numar_pozitie=i.Numar_pozitie 
	where (coalesce(d.termen,'')<>coalesce(i.termen,'') or isnull(d.explicatii,'')<>isnull(i.explicatii,''))

	create table #RNmodDate (idContract int not null)
/*
	select p.idContract,*, --*/ update p set
		termen=n.termen, explicatii=n.explicatii
	output inserted.idcontract into #RNmodDate 
	from PozContracte p join Contracte c on c.idContract=p.idContract
		join #NAmodDate n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
	where isnull(p.termen,'')<>isnull(n.termen,'') or isnull(p.explicatii,'')<>isnull(n.explicatii,'')
	
	
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 
