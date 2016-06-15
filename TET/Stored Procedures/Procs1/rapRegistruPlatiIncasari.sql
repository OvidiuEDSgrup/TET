--***
create procedure rapRegistruPlatiIncasari (@sesiune varchar(50)=null, @datajos datetime, @datasus datetime, @cont varchar(40)=null, @locm varchar(20)=null)
	/**filtrare pe conturile asociate utilizatorilor (CONTPLIN)*/
as
declare @eroare varchar(2000)
begin try
	declare @eContUtiliz int
	declare @ContUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @ContUtiliz(valoare, cod_proprietate)
	select rtrim(valoare),cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='CONTPLIN'
	delete c from @ContUtiliz c where exists (select 1 from @ContUtiliz cc		-- eliminare conturi ale caror parinti apar de asemenea
		where c.valoare like cc.valoare+'%' and c.valoare<>cc.valoare)	-- (oricum, situatia tratata aici este contraindicata)
	set @eContUtiliz=isnull((select max(1) from @ContUtiliz),0)

		/**filtrare pe locurile de munca asociate utilizatorilor (LOCMUNCA)*/
	declare @utilizator varchar(20), @eLocmUtiliz int
	select @utilizator=dbo.fiautilizator(@sesiune)
	declare @LocmUtiliz table(valoare varchar(200))
	insert into @LocmUtiliz(valoare)
	select cod from lmfiltrare l where l.utilizator=@utilizator
	set @eLocmUtiliz=isnull((select max(1) from @LocmUtiliz),0)


	select p.data, p.plata_incasare, p.numar, p.explicatii, 
	(case when left(p.plata_incasare, 1)='I' then p.suma else 0 end) as incasari, 
	(case when left(p.plata_incasare, 1)='P' then p.suma else 0 end) as plati,
	rtrim(p.cont) cont
	from pozplin p
	where p.subunitate=(select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO')
	and p.data between @datajos and @datasus
	and (@cont is null or p.Cont like @cont+'%')
	and (@locm is null or p.Loc_de_munca like @locm+'%')
	and (@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where cont like u.valoare+'%'))
	and (@eLocmUtiliz=0 or exists (select 1 from @LocmUtiliz u where p.Loc_de_munca like u.valoare+'%'))

	order by p.data, p.tert, p.factura, p.loc_de_munca
end try
begin catch
	set @eroare=error_message()+'(rapRegistruPlatiIncasari - L'+convert(varchar(20),error_line())+')'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
