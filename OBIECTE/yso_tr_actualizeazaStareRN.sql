--***
if exists (select * from sysobjects where name ='yso_tr_actualizeazaRN' and xtype='TR')
	drop trigger yso_tr_actualizeazaRN
go
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
