CREATE TABLE [dbo].[JurnalContracte] (
    [idJurnal]   INT           IDENTITY (1, 1) NOT NULL,
    [idContract] INT           NULL,
    [data]       DATETIME      NULL,
    [stare]      INT           NULL,
    [explicatii] VARCHAR (60)  NULL,
    [detalii]    XML           NULL,
    [utilizator] VARCHAR (100) NULL,
    CONSTRAINT [PK_JurnalContracte] PRIMARY KEY CLUSTERED ([idJurnal] ASC),
    CONSTRAINT [FK_JurnalContracte_idContract] FOREIGN KEY ([idContract]) REFERENCES [dbo].[Contracte] ([idContract])
);


GO
CREATE NONCLUSTERED INDEX [IX_idContract]
    ON [dbo].[JurnalContracte]([idContract] ASC);


GO
--***
create trigger tr_RezervaLaDefinitivare on jurnalContracte after insert,update,delete
as
begin try
if exists (select * from sysobjects where name ='RezervaLaIntrareInStoc')
begin
	
	declare @stareDefinitiva int
	select top 1 @stareDefinitiva=stare from StariContracte where tipContract='CL' and modificabil=0 order by stare

	select distinct i.idContract into #contracte 
		from inserted i 
		JOIN StariContracte st on st.tipContract='CL' and i.stare=st.stare and st.inchisa=1
		JOIN Contracte c on c.idContract=i.idContract
		where c.tip='CL'
	
	/*	Am de sters rezervari daca exista (am jurnalizare de comenenzi in stari inchise)	*/
	IF EXISTS (select 1 from #contracte)
		exec wStergRezervariComenzi @sesiune='', @parXML=NULL

	select distinct pc.cod,isnull(nullif(pc.detalii.value('(/row/@gestiune)[1]','varchar(20)'),''),c.gestiune) as gestiune,i.data
	into #coduriderezolvat
	from inserted i
	inner join pozContracte pc on i.idContract=pc.idContract
	inner join contracte c on i.idContract=c.idContract
	where c.tip='CL' and i.stare=@stareDefinitiva and i.explicatii!='Generare rezervare' --sa nu autobuclam la infinit

	
	/*	Am de facut rezervari (am jurnalizare de comenzi definitive)	*/
	IF EXISTS (select 1 from #coduriderezolvat)
	begin
		select 'I' as tiplinie,dr.cod,dr.gestiune,sum(s.stoc) as cantitate,dr.data
		into #tmpderezervat 
		from #coduriderezolvat dr
		inner join stocuri s on s.Cod_gestiune=dr.gestiune and s.cod=dr.cod
		group by dr.cod,dr.gestiune,dr.data

		exec RezervaLaIntrareInStoc
	end
end
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 

