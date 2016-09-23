IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_wIaPreturiIntrarePozDoc')
	DROP PROCEDURE yso_wIaPreturiIntrarePozDoc
GO

CREATE PROCEDURE yso_wIaPreturiIntrarePozDoc @sesiune VARCHAR(50)=NULL, @parXML XML=NULL
AS
BEGIN TRY
	set transaction isolation level read uncommitted
	declare @subunitate varchar(20)='1', @rotunjire int='2'
	select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),  
	   @rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)  
	 from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')  

	if OBJECT_ID('tempdb..#coduri') is not null drop table #coduri
	
	;with 
	predari as
		(select p.Subunitate, p.Numar, p.Data, p.Cod, p.Gestiune, p.Cod_intrare
			,cant_predare=SUM(p.Cantitate),val_predare=SUM(p.Cantitate*p.Pret_de_stoc)
			,cant_predare_doc=sum(sum(p.Cantitate)) over(partition by p.subunitate,p.numar,p.data)
			,nr_codi_doc=ROW_NUMBER() over(partition by p.subunitate,p.numar,p.data order by p.gestiune, p.cod_intrare)	
		from pozdoc p where p.Subunitate='1' and p.Tip='PP'
		group by p.Subunitate, p.Numar, p.Data, p.Cod, p.Gestiune, p.Cod_intrare)
	,consumuri as
		(select c.Subunitate, c.Numar, c.Data
			,cant_consum=SUM(c.Cantitate)
			,val_consum=SUM(c.Cantitate*c.Pret_de_stoc)	
		from pozdoc c 
		where c.Subunitate='1' and c.Tip='CM' 
		group by c.Subunitate, c.Numar, c.Data)
	,coduri as
		(select p.Subunitate, p.data, p.Cod, 
			Gestiune=convert(varchar(20),p.Gestiune), Cod_intrare=convert(varchar(20),p.Cod_intrare)
			,pret_intrare=c.val_consum/p.cant_predare_doc 
			,Nivel=0
		from predari p 
			inner join consumuri c on p.Subunitate=c.Subunitate and p.Numar=c.Numar and p.Data=c.Data 
		union all
		select c.Subunitate, c.data, c.Cod, 
			Gestiune=convert(varchar(20),p.Gestiune_primitoare), Cod_intrare=convert(varchar(20),p.Cod_intrare_primitor)
			,c.pret_intrare
			,Nivel=c.Nivel+1
		from coduri c 
			cross apply yso_fTransferuriPachete(c.Subunitate,c.Cod,c.Gestiune,c.Cod_intrare,c.data) p
		where c.Nivel<=10)
	--*/
	
	select subunitate,data,cod,gestiune,cod_intrare,pret_intrare,Nivel
	into #coduri
	from coduri c 
	
	create nonclustered index princ on #coduri (subunitate,data,cod,gestiune,cod_intrare)
	
	IF OBJECT_ID('tempdb..#yso_PreturiIntrarePozDoc') IS NULL
		CREATE TABLE #yso_PreturiIntrarePozDoc
		(idPozDoc int PRIMARY KEY NONCLUSTERED, 
			subunitate varchar(9), tip char(2), data datetime, cod varchar(20), 
			gestiune varchar(20), cod_intrare varchar(20), yso_pret_intrare float)
	
	update p set 
		yso_pret_intrare=c.pret_intrare
	--into #pozdoc
	from #yso_PreturiIntrarePozDoc p 
		outer apply (select top 1 * from #coduri c
			where c.Subunitate=p.Subunitate and c.Cod=p.Cod and c.Gestiune=p.Gestiune and c.Cod_intrare=p.Cod_intrare
			order by ABS(DATEDIFF(M,c.Data,p.Data)), sign(DATEDIFF(M,c.Data,p.Data)) desc) c
	where p.tip in ('AP','AC','AS')
		

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH