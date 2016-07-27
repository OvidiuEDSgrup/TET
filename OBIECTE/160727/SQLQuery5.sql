--drop FUNCTION [dbo].[yso_Pozdoc_pret_intrare] GO
--declare/* pt teste decomenteaza aici
CREATE FUNCTION [dbo].[yso_Pozdoc_pret_intrare] (
--*/
	@Data_doc_de_la datetime=null,@Data_doc_pana_la datetime=null
	,@Loc_de_munca nvarchar(4000)=null,@Tert nvarchar(4000)=null,@Grupa_articole nvarchar(4000)=null,@Cod_articol nvarchar(4000)=null
	,@Doar_pachete bit=null,@Echipa nvarchar(4000)=null,@Grupa_terti nvarchar(4000)=null
/*
declare --*/ ) returns

	)
/* si comenteaza aici
select @Data_doc_de_la='2016-07-25',@Data_doc_pana_la='2016-07-27'
	,@Loc_de_munca=null,@Tert=NULL,@Grupa_articole=null,@Cod_articol='98624703',@Doar_pachete=0,@Echipa=null
--*/
AS
BEGIN

declare @subunitate varchar(20)='1', @rotunjire int='2'
select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),  
   @rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)  
 from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')  

declare @coduri table (id_codi int identity(1,1) PRIMARY KEY CLUSTERED, 
	subunitate varchar(9), data datetime, cod varchar(20), 
	gestiune varchar(20), cod_intrare varchar(20),pret_intrare float, nivel int
	, UNIQUE NONCLUSTERED (subunitate,data,cod,gestiune,cod_intrare,id_codi)

--/*
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
		--,pret_intrare=SUM(c.Cantitate*c.Pret_de_stoc)/sum(p.cant_predare_doc) 
	from pozdoc c 
	where c.Subunitate='1' and c.Tip='CM' --and p.idPozDoc=38631
	group by c.Subunitate, c.Numar, c.Data)
,coduri as
	(select p.Subunitate, p.data, p.Cod, 
		Gestiune=convert(varchar(20),p.Gestiune), Cod_intrare=convert(varchar(20),p.Cod_intrare)
		,pret_intrare=c.val_consum/p.cant_predare_doc 
		,Nivel=0
	from predari p 
		inner join consumuri c on p.Subunitate=c.Subunitate and p.Numar=c.Numar and p.Data=c.Data --and p.nr_codi_doc=1
	union all
	select c.Subunitate, c.data, c.Cod, 
		Gestiune=convert(varchar(20),p.Gestiune_primitoare), Cod_intrare=convert(varchar(20),p.Cod_intrare_primitor)
		,c.pret_intrare
		,Nivel=c.Nivel+1
	from coduri c 
		cross apply yso_fTransferuriPachete(c.Subunitate,c.Cod,c.Gestiune,c.Cod_intrare,c.data) p
	where c.Nivel<=10)
--*/
insert into @coduri (subunitate,data,cod,gestiune,cod_intrare,pret_intrare,nivel)
select subunitate,data,cod,gestiune,cod_intrare,pret_intrare,Nivel
--into #coduri
from coduri c 

--create nonclustered index princ on @coduri 

--end try
--begin catch
--end catch

select 
	yso_pret_intrare=isnull(c.pret_intrare,p.Pret_de_stoc),
	yso_val_intrare=isnull(p.cantitate*c.pret_intrare,p.Cantitate*p.Pret_de_stoc),
	p.*
--into #pozdoc
from pozdoc p 
	outer apply (select top 1 * from @coduri c
		where c.Subunitate=p.Subunitate and c.Cod=p.Cod and c.Gestiune=p.Gestiune and c.Cod_intrare=p.Cod_intrare
		order by ABS(DATEDIFF(M,c.Data,p.Data)), sign(DATEDIFF(M,c.Data,p.Data)) desc) c
where p.tip in ('AP','AC','AS')
	 and p.data>=@Data_doc_de_la and p.data<=@Data_doc_pana_la
	 and left(p.Cont_venituri,3) in ('707','709')
	AND (isnull(@Loc_de_munca,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@Loc_de_munca)))
	AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
	AND (isnull(@Cod_articol,  '') = '' OR p.cod = rtrim(rtrim(@Cod_articol)))
return 
END