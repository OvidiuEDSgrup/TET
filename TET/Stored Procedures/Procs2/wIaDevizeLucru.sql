--***
create procedure wIaDevizeLucru @sesiune varchar(50), @parXML xml
as
if exists(select 1 from sys.sysobjects where name = 'wIaDevizeLucruSP' and type = 'P')
	exec wIaDevizeLucruSP @sesiune, @parXML
else      
begin try
	set transaction isolation level read uncommitted

	declare
		@datajos datetime, @datasus datetime, @nrdeviz varchar(20), @filtrutipdeviz varchar(100), 
		@filtrunrdeviz varchar(100), @filtrunrinmatriculare varchar(100), @filtrubeneficiar varchar(100), 
		@filtrupostlucru varchar(100), @filtrukmbordj float, @filtrukmbords float, @filtruvaloaredevizj float, 
		@filtrustare varchar(100), @filtruvaloaredevizs float

	set @filtrutipdeviz = isnull(@parXML.value('(/row/@filtrutipdeviz)[1]','varchar(100)'),'in lucru')+'%'
	set @filtrunrdeviz = @parXML.value('(/row/@filtrunrdeviz)[1]','varchar(100)')
	set @filtrunrinmatriculare = '%'+isnull(@parXML.value('(/row/@filtrunrinmatriculare)[1]','varchar(100)'),'')+'%'
	set @filtrubeneficiar = '%'+isnull(@parXML.value('(/row/@filtrubeneficiar)[1]','varchar(100)'),'')+'%'
	set @filtrupostlucru= isnull(@parXML.value('(/row/@filtrupostlucru)[1]','varchar(100)'),'')
	set @filtrukmbordj = isnull(@parXML.value('(/row/@filtrukmbordj)[1]', 'float'), 0)
	set @filtrukmbords = isnull(@parXML.value('(/row/@filtrukmbords)[1]','float'), 999999999)
	set @filtruvaloaredevizj = isnull(@parXML.value('(/row/@filtruvaloaredevizj)[1]', 'float'), 0)
	set @filtruvaloaredevizs = isnull(@parXML.value('(/row/@filtruvaloaredevizs)[1]', 'float'), 999999999)
	set @datajos = @parXML.value('(/row/@datajos)[1]','datetime')
	set @datasus = @parXML.value('(/row/@datasus)[1]','datetime')
	set @filtrustare = isnull(@parXML.value('(/row/@filtrustare)[1]','varchar(100)'),'')+'%'

	if (@filtrunrdeviz is not null)
	begin
		set @datajos=isnull(@datajos,'1901-1-1')
		set @datasus=isnull(@datasus,'2999-1-1')
	end

	set @nrdeviz = @parXML.value('(/row/@nrdeviz)[1]','varchar(100)')

	select top 100
		RTRIM(dv.Cod_deviz) as nrdeviz,
		RTRIM(dv.Denumire_deviz) as nrinmatriculare,
		RTRIM (convert(varchar(20),dv.Data_lansarii,101)) as dataincepere,
		RTRIM(dv.Ora_lansarii) as oraincepere,
		RTRIM (convert(varchar(20),dv.Data_inchiderii,101)) as datainchiderii,
		RTRIM(dv.Autovehicul) as autovehicul,
		rtrim(a.Nr_circulatie) + ' - ' + rtrim(a.Marca) + ' ' + rtrim(a.Model) as denautovehicul,
		convert(decimal(17,0),dv.km_bord) as kmbord,
		RTRIM(dv.Executant) as postlucru, 
		RTRIM(isnull(p.Denumire,'')) as denpostlucru, 
		RTRIM(dv.Beneficiar) as beneficiar, 
		RTRIM(isnull(t.Denumire,'')) as denbeneficiar,
		convert(decimal(17,2),dv.Valoare_deviz) as valoaredeviz,
		convert(decimal(17,2),dv.Valoare_realizari) as valoarerealizari,
		RTRIM(dv.Sesizare_client) as sesizareclient,
		RTRIM(dv.Constatare_service) as constatareservice,
		RTRIM(dv.Observatii) as obs,
		RTRIM(dv.Stare) as stare,
		(case when dv.Stare = 0 then 'Neacceptat' 
			  when dv.Stare = 1 then 'Lucru' 
			  when dv.Stare = 2 then (case when dv.Tip = 'B' then 'Finalizat - de facturat' else 'Finalizat' end)
			  else 'Facturat' end) as denstare,
		RTRIM (convert(varchar(20),dv.Termen_de_executie,101)) as termenexecutie,
		RTRIM(dv.Ora_executie) as oraexecutie,
		RTRIM(dv.Numar_de_dosar) as nrdosar,
		RTRIM(dv.Tip) as tipdeviz,
		RTRIM(dv.Factura) as factura,
		rtrim(prg.Numar_curent) as programare,
		rtrim(prg.Descriere_problema) as denprogramare,
		--in functie de "stare" se atribuie o anumita culoare inregistrarilor
	   (case when dv.stare = 0 then '#000000' when dv.stare = 1 then '#0000FF' 
			 when dv.stare= 2 then '#FF0000'/*'#01D758' '#33CC33'*/ else '#808080' end)  as culoare,
				-- stare = 0 - Neacceptat; (negru)
				-- stare = 1 - Lucru;      (albastru)
				-- stare = 2 - Finalizat;  (fost verde) rosu
				-- stare = 3 - Facturat    (fost maro) gri

		--se numara de pe coloana Cod_deviz intrarile pt a fi calculat nr total de pozitii pt fiecare cod, in coloana nou creata "nrpozitii"
		(select COUNT(1) from pozdevauto pd where pd.tip='D' and pd.Cod_deviz=dv.Cod_deviz) as nrpozitii,

		/*urmatoarele campuri sunt doar pentru formular	*/
		'QE' /*'DV'*/ as tip, --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		RTRIM (convert(varchar(20),dv.Data_lansarii,101)) as data,
		RTRIM(dv.Cod_deviz) as numar
		from devauto dv
		Left outer join terti t on t.Tert=dv.beneficiar
		Left outer join Posturi_de_lucru p on p.Postul_de_lucru = convert(int, rtrim((case when 
			ISNUMERIC(dv.Executant) = 1 then dv.Executant else '0' end)))
		left join Programator prg on prg.Deviz = dv.Cod_deviz
		left join auto a on a.Cod = dv.Autovehicul
		where (@nrdeviz is null or dv.Cod_deviz = @nrdeviz) 
			and (@nrdeviz is not null or dv.Data_lansarii between @datajos and @datasus)
			and (@filtrunrdeviz is null or dv.Cod_deviz like '%' + replace(isnull(@filtrunrdeviz, ''), ' ', '%') + '%')
			and dv.Denumire_deviz like @filtrunrinmatriculare
			and (dv.Beneficiar like @filtrubeneficiar or isnull(t.Denumire,'') like @filtrubeneficiar)
			and (case when dv.Stare = 0 then 'Neacceptat' 
					  when dv.Stare = 1 then 'Lucru' 
					  when dv.Stare = 2 then (case when dv.Tip = 'B' then 'Finalizat - de facturat' else 'Finalizat' end) 
					  else 'Facturat' end) like @filtrustare
			and (case when (dv.Tip = 'B' and dv.Stare <> 3) then 'de facturat' 
					  when (dv.Tip = '' and dv.Stare <> 3) then 'in lucru' 
					  when dv.Tip = 'N' then 'inchis' 
					  else '' end) like @filtrutipdeviz
			and (case when isnumeric(@filtrupostlucru) = 1 then dv.Executant else p.Denumire end) like '%' + @filtrupostlucru + '%'
			and (dv.KM_bord between @filtrukmbordj and @filtrukmbords)
			and (dv.Valoare_deviz between @filtruvaloaredevizj and @filtruvaloaredevizs)
		order by data_lansarii desc
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
