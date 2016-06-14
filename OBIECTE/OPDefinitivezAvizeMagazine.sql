drop proc OPDefinitivezAvizeMagazine
go
create procedure OPDefinitivezAvizeMagazine as

declare @err nvarchar(500)

begin try

	alter table pozdoc disable trigger all
	/*
	select p.Stare,*
	--*/ update p set Stare=2
	from pozdoc p cross join
		(select top 1 data=dbo.eom(rtrim(anul)+'-'+rtrim(luna)+'-01')+1 from 
			(select anul=a.Val_numerica,luna=l.val_numerica, l.Denumire_parametru 
			from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
				and a.Parametru='ANULINC' where l.Tip_parametru='GE' and l.Parametru='LUNAINC'
			union 
			select a.Val_numerica,l.val_numerica, l.Denumire_parametru 
			from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
				and a.Parametru='ANULBLOC' where l.Tip_parametru='GE' and l.Parametru='LUNABLOC'
			union 
			select a.Val_numerica,l.val_numerica, l.Denumire_parametru 
			from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
				and a.Parametru='ANULIMPL' where l.Tip_parametru='GE' and l.Parametru='LUNAIMPL') par
			where isdate(rtrim(anul)+'-'+rtrim(luna)+'-01')=1
		order by anul desc, luna desc) inf
	where p.Subunitate='1' and p.Tip='AP' and p.Data>=inf.data and p.Data <= dateadd(d,-1,GETDATE())
		and p.Stare<>2
		and (p.Utilizator like 'MAGAZIN%' or p.Gestiune like '21[1-9]%')

	alter table pozdoc enable trigger all

end try
begin catch
	if exists (select top 1 t.is_disabled from sys.triggers t join sys.objects o on o.object_id=t.object_id 
			where o.type='U' and o.name='pozdoc' and t.is_disabled=1)
		alter table pozdoc enable trigger all
			
	set @err=ERROR_MESSAGE()
	raiserror(@err,11,1)
end catch