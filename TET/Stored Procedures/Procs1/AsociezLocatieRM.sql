CREATE PROCEDURE [dbo].AsociezLocatieRM @subunitate	char(9),@Tip char(2),@Numar	char(8),@Data datetime as
--DECLARE @subunitate	char(9),@Tip char(2),@Numar	char(8),@Data datetime
--select @Tip=p.Tip, @Numar=p.numar,@data=p.data from pozdoc p where p.Subunitate=@subunitate and p.Tip='RM' and p.Numar='5364'

if ISNULL(@subunitate,'')=''
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output

--select (select TOP 1 sl.Locatie from stoclim sl 
--where sl.Subunitate=p.Subunitate and sl.Cod_gestiune=p.Gestiune and sl.cod=p.Cod and sl.data='2999-12-31')
--,* from pozdoc p where p.Subunitate=@subunitate and p.tip='RM' and p.Locatie=''

--select *
update pozdoc set Locatie= s.Locatie --isnull((select TOP 1 sl.Locatie from stoclim sl where sl.Subunitate=p.Subunitate and sl.Cod_gestiune=p.Gestiune and sl.cod=p.Cod and sl.data='2999-12-31'),'')
from pozdoc p 
	inner join gestiuni g on g.Cod_gestiune=p.Gestiune
	inner join stoclim s on s.Subunitate=p.Subunitate and s.Tip_gestiune=g.Tip_gestiune and s.Cod_gestiune=p.Gestiune
		and s.Cod=p.Cod and s.Data='2999-12-31'
where p.Subunitate=@subunitate and p.Numar=@Numar and p.Data=@Data
and p.tip='RM' and nullif(p.Locatie,'') is null--<>s.Locatie

update s set Locatie= p.Locatie --isnull((select TOP 1 sl.Locatie from stoclim sl where sl.Subunitate=p.Subunitate and sl.Cod_gestiune=p.Gestiune and sl.cod=p.Cod and sl.data='2999-12-31'),'')
from pozdoc p 
	inner join gestiuni g on g.Cod_gestiune=p.Gestiune
	inner join stoclim s on s.Subunitate=p.Subunitate and s.Tip_gestiune=g.Tip_gestiune and s.Cod_gestiune=p.Gestiune
		and s.Cod=p.Cod and s.Data='2999-12-31'
where p.Subunitate=@subunitate and p.Numar=@Numar and p.Data=@Data
and p.tip='RM' and p.Locatie<>s.Locatie

IF @@TRANCOUNT > 0 COMMIT TRAN
--select (select 1 from pozdoc p where p.subunitate='1' and p.tip='RM' and p.numar=@numar and p.data=@data and p.locatie='' 
--and exists (select 1 from stoclim sl 
--		where sl.Subunitate=p.Subunitate and sl.Cod_gestiune=p.Gestiune and sl.cod=p.Cod and sl.data='2999-12-31') )
