--***
/**	procedura pentru actualizare date salariati	operate in avans in CTRL+D pt. generare registru */
Create procedure Actualizare_date_salariati 
	(@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLocm char(9), @calculLich int=0)
as
/*
	Exemplu de apel:
	exec as login='cluj\lucian'
	declare @dataJos datetime, @dataSus datetime, @pMarca char(6), @pLocm char(9)
	select @dataJos='12/01/2014', @dataSus='12/31/2014', @pMarca='256005', @pLocm='256'
	exec Actualizare_date_salariati @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @pLocm=@pLocm
*/
begin 
	declare @utilizator varchar(20), @lista_lm int, @DataJnext datetime, @DataSnext datetime, @lBuget int, 
		@lunaInch int, @anulInch int, @dataInch datetime

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @lBuget=dbo.iauParL('PS','UNITBUGET')

--	daca procedura este apelata de la calcul salarii/lichidare (pentru cazurile in care se opereaza modificari de date dupa inchiderea lunii anterioare)
	if @calculLich=1
	begin
		set @lunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
		set @anulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
		set @dataInch=dbo.eom(convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))
		if @dataJos<>DateAdd(day,1,@dataInch)
			return
		else
		begin
			set @DataJnext=@dataJos
			set @DataSnext=@dataSus
		end
	end
--	daca procedura este apelata de la inchidere luna (asa a functionat initial - doar de la inchidere de luna)
	else
	begin	
		set @DataJnext=Dateadd(day,1,@dataSus)
		set @DataSnext=dbo.eom(Dateadd(day,1,@dataSus))
	end

	if object_id('tempdb..#ultimaModif') is not null 
		drop table #ultimaModif
--	pun intr-o tabela temporara ultima valoare pentru fiecare tip de modificare (cazul in care sunt mai multe modificari intr-o luna sa se transpuna in personal, ultima modificare).
	select * into #ultimaModif from 
	(select e.Marca, e.Cod_inf, e.Val_inf, e.Data_inf, e.Procent, RANK() over (partition by e.Marca, e.Cod_inf order by e.Data_inf Desc) as ordine
	from extinfop e 
		left outer join personal p on p.marca=e.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where e.Data_inf between @DataJnext and @DataSnext
		and e.Cod_inf in ('CONDITIIM','SALAR','DATAMRL','DATAMDCTR','DATAMFCT','DATAMLM')
		and (@pLocm='' or p.loc_de_munca like rtrim(@pLocm)+'%') 
		and (@lista_lm=0 or lu.cod is not null)  
		and (e.Val_inf<>'' or e.Procent<>0)) a
	where Ordine=1

	update personal set Salar_de_incadrare=(case when isnull(s.Procent,0)<>0 and @lBuget=0 then isnull(s.Procent,0) else Salar_de_incadrare end), 
		Salar_de_baza=(case when isnull(s.Procent,0)<>0 and @lBuget=0 then isnull(s.Procent,0) else Salar_de_baza end), 
		Grupa_de_munca=(case when isnull(ltrim(rtrim(g.Val_inf)),'')<>'' then upper(isnull(ltrim(rtrim(g.Val_inf)),'')) else Grupa_de_munca end), 
		Salar_lunar_de_baza=(case when isnull(r.Procent,0)<>0 then isnull(r.Procent,0) else Salar_lunar_de_baza end),
--	adaugat (01.11.2011) actualizare functie, loc de munca, mod angajare, data de sfarsit contract pe perioada determinata
		Mod_angajare=(case when isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and isnull(m.Val_inf,'') in ('N','D','T') then upper(isnull(ltrim(rtrim(m.Val_inf)),'')) else Mod_angajare end),
		Data_plec=(case when a.Mod_angajare='D' and convert(char(1),a.loc_ramas_vacant)='0'
			and (isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and left(isnull(m.Val_inf,''),2)+'/'+substring(isnull(m.Val_inf,''),4,2)+'/'+right(rtrim(isnull(m.Val_inf,'')),4)=rtrim(isnull(m.Val_inf,''))
				or isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and left(isnull(m.Val_inf,''),2)+'.'+substring(isnull(m.Val_inf,''),4,2)+'.'+right(rtrim(isnull(m.Val_inf,'')),4)=rtrim(isnull(m.Val_inf,'')))
			then convert(datetime,isnull(m.Val_inf,''),103) 
			when isnull(m.Val_inf,'')='N' and convert(char(1),a.loc_ramas_vacant)='0' then '01/01/1901' else Data_plec end),
		Zile_absente_an=(case when isnull(m.Val_inf,'')='N' and convert(char(1),a.loc_ramas_vacant)='0' then 0 else Zile_absente_an end),
		Cod_functie=(case when isnull(ltrim(rtrim(f.Val_inf)),'')<>'' and isnull(f.Val_inf,'') in (select Cod_functie from functii) then isnull(ltrim(rtrim(f.Val_inf)),'') else Cod_functie end),
		Loc_de_munca=(case when isnull(ltrim(rtrim(l.Val_inf)),'')<>'' and isnull(l.Val_inf,'') in (select Cod from lm) then isnull(ltrim(rtrim(l.Val_inf)),'') else Loc_de_munca end)
	from personal a
		left outer join #ultimaModif g on a.Marca=g.Marca and g.Cod_inf='CONDITIIM' and g.Data_inf between @DataJnext and @DataSnext
		left outer join #ultimaModif s on @lBuget=0 and a.Marca=s.Marca and s.Cod_inf='SALAR' and s.Data_inf between @DataJnext and @DataSnext
		left outer join #ultimaModif r on a.Marca=r.Marca and r.Cod_inf='DATAMRL' and r.Data_inf between @DataJnext and @DataSnext
		left outer join #ultimaModif m on a.Marca=m.Marca and m.Cod_inf='DATAMDCTR' and m.Data_inf between @DataJnext and @DataSnext
		left outer join #ultimaModif f on a.Marca=f.Marca and f.Cod_inf='DATAMFCT' and f.Data_inf between @DataJnext and @DataSnext
		left outer join #ultimaModif l on a.Marca=l.Marca and l.Cod_inf='DATAMLM' and l.Data_inf between @DataJnext and @DataSnext
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.loc_de_munca
	where (@pMarca='' or a.marca=@pMarca) 
		and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') 
		and (@lista_lm=0 or lu.cod is not null) 
		and a.data_angajarii_in_unitate<=dbo.eom(@DataJnext)
		and (convert(char(1),a.loc_ramas_vacant)='0' or a.data_plec>@DataJnext)
		and (isnull(ltrim(rtrim(g.Val_inf)),'')<>'' or isnull(s.Procent,0)<>0 and @lBuget=0 or isnull(r.Procent,0)<>0
		or isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and isnull(m.Val_inf,'') in ('N','D','T') 
		or a.Mod_angajare='D' 
			and (isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and left(isnull(m.Val_inf,''),2)+'/'+substring(isnull(m.Val_inf,''),4,2)+'/'+right(rtrim(isnull(m.Val_inf,'')),4)=rtrim(isnull(m.Val_inf,''))
			or isnull(ltrim(rtrim(m.Val_inf)),'')<>'' and left(isnull(m.Val_inf,''),2)+'.'+substring(isnull(m.Val_inf,''),4,2)+'.'+right(rtrim(isnull(m.Val_inf,'')),4)=rtrim(isnull(m.Val_inf,'')))
		or isnull(ltrim(rtrim(f.Val_inf)),'')<>'' and isnull(f.Val_inf,'') in (select Cod_functie from functii)
		or isnull(ltrim(rtrim(l.Val_inf)),'')<>'' and isnull(l.Val_inf,'') in (select Cod from lm))
end
/*
	exec Actualizare_date_salariati '05/01/2011', '05/31/2011', '80984', ''
*/
