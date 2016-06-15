--***
CREATE procedure [dbo].[YSO_wIaDevizeLucru] @sesiune varchar(50), @parXML XML
as
     
begin
set transaction isolation level READ UNCOMMITTED

Declare @datajos datetime, @datasus datetime, @nrdeviz varchar(20), @filtrutipdeviz varchar(100), 
	@filtrunrdeviz varchar(100), @filtrunrinmatriculare varchar(100), @filtrubeneficiar varchar(100), 
	@filtrupostlucru varchar(100), @filtrukmbord float, @filtruvaloaredeviz float, 
	@filtrustare varchar(100), @filtrusesizareclient varchar(100), @filtruconstatareservice varchar(100),
	@utilizator varchar(20),@filtrulm varchar(20)

Set @filtrutipdeviz = isnull(@parXML.value('(/row/@filtrutipdeviz)[1]','varchar(100)'),'in lucru')+'%'
Set @filtrunrdeviz = @parXML.value('(/row/@filtrunrdeviz)[1]','varchar(100)')
Set @filtrunrinmatriculare = '%'+isnull(@parXML.value('(/row/@filtrunrinmatriculare)[1]','varchar(100)'),'')+'%'
/*Set @dataincepere = (@parXML.value('(/row/@dataincepere)[1]','datetime'))
Set @datainchiderii =(@parXML.value('(/row/@datainchiderii)[1]','datetime'))*/
Set @filtrubeneficiar = '%'+isnull(@parXML.value('(/row/@filtrubeneficiar)[1]','varchar(100)'),'')+'%'
--set @filtrudenbeneficiar = '%'+isnull(@parXML.value('(/row/@filtrudenumirebeneficiar)[1]','varchar(100)'),'')+'%'
Set @filtrupostlucru= '%'+isnull(@parXML.value('(/row/@filtrupostlucru)[1]','varchar(100)'),'')+'%'
Set @filtrukmbord=isnull(@parXML.value('(/row/@filtrukmbord)[1]','float'),999999999)
Set @filtruvaloaredeviz=isnull(@parXML.value('(/row/@filtruvaloaredeviz)[1]','float'),999999999)
Set @datajos = @parXML.value('(/row/@datajos)[1]','datetime')
Set @datasus = @parXML.value('(/row/@datasus)[1]','datetime')
Set @filtrustare = isnull(@parXML.value('(/row/@filtrustare)[1]','varchar(100)'),'')+'%'
Set @filtrusesizareclient = '%'+isnull(@parXML.value('(/row/@filtrusesizareclient)[1]','varchar(100)'),'')+'%'
Set @filtruconstatareservice = '%'+isnull(@parXML.value('(/row/@filtruconstatareservice)[1]','varchar(100)'),'')+'%'
set @filtrulm=rtrim(ltrim(isnull(@parXML.value('(/row/@filtrulocmunca)[1]','varchar(20)'),'')))

if (@filtrunrdeviz is not null)
begin
	set @datajos=isnull(@datajos,'1901-1-1')
	set @datasus=isnull(@datasus,'2999-1-1')
end
--set @filtrunrdeviz='%'+replace(isnull(@filtrunrdeviz,''),' ','%')+'%'
Set @nrdeviz = @parXML.value('(/row/@nrdeviz)[1]','varchar(100)')

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

select top 100
	RTRIM(dv.Cod_deviz) as nrdeviz,
	RTRIM(dv.Denumire_deviz) as nrinmatriculare,
	RTRIM (convert(varchar(20),dv.Data_lansarii,101)) as dataincepere,
	RTRIM(dv.Ora_lansarii) as oraincepere,
	RTRIM (convert(varchar(20),dv.Data_inchiderii,101)) as datainchiderii,
	RTRIM(dv.Autovehicul) as autovehicul,
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
	RTRIM (convert(varchar(20),dv.Termen_de_executie,101)) as termenexecutie,
	RTRIM(dv.Ora_executie) as oraexecutie,
	RTRIM(dv.Numar_de_dosar) as nrdosar,
	RTRIM(dv.Tip) as tipdeviz,
	RTRIM(dv.Factura) as factura,
	lm.Denumire as denlm,
	--in functie de "stare" se atribuie o anumita culoare inregistrarilor
   (case when dv.stare = 0 then '#000000' when dv.stare = 1 then '#0000FF' 
	     when dv.stare= 2 then '#33CC33' else '#993300' end)  as culoare,
			-- stare = 0 - Neacceptat; (negru)
			-- stare = 1 - Lucru;      (albastru)
			-- stare = 2 - Finalizat;  (verde)
			-- stare = 3 - Facturat    (maro)

	--se numara de pe coloana Cod_deviz intrarile pt a fi calculat nr total de pozitii pt fiecare cod, in coloana nou creata "nrpozitii"
	(case when dv.Stare = 0 then 'Neacceptat' 
						  when dv.Stare = 1 then 'Lucru' 
						  when dv.Stare = 2 then 'Finalizat' 
											else 'Facturat' end)  as denstare,
	(select COUNT(1) from pozdevauto pd 
				 where pd.tip='D' and pd.Cod_deviz=dv.Cod_deviz) as nrpozitii,
	/*urmatoarele campuri sunt doar pentru formular	*/
	'QT' /*'DV'*/ as tip, --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	RTRIM (convert(varchar(20),dv.Data_lansarii,101)) as data,
	RTRIM(dv.Cod_deviz) as numar--, terti.denumire as dfs,'c' c
				From devauto dv
				Left outer join terti t on /*terti.subunitate='1' and */t.Tert=dv.beneficiar
				Left outer join Posturi_de_lucru p on p.Postul_de_lucru=convert(int,rtrim((case when 
					ISNUMERIC(dv.Executant)=1 then dv.Executant else '0' end)))
				left outer join lm on lm.Cod=p.Loc_de_munca
				Where 
				(@nrdeviz is null or dv.Cod_deviz=@nrdeviz) 
				and (@nrdeviz is not null or dv.Data_lansarii between @datajos and @datasus)
				and (@filtrunrdeviz is null or dv.Cod_deviz like '%'+replace(isnull(@filtrunrdeviz,''),' ','%')+'%')
				and dv.Denumire_deviz like @filtrunrinmatriculare
				and dv.Beneficiar like @filtrubeneficiar
				and isnull(t.Denumire,'') like @filtrubeneficiar
				and (case when dv.Stare = 0 then 'Neacceptat' 
						  when dv.Stare = 1 then 'Lucru' 
						  when dv.Stare = 2 then 'Finalizat' 
											else 'Facturat' end) like @filtrustare
				and (case when dv.Tip = 'B' then 'de facturat' 
						  when dv.Tip = '' then 'in lucru' 
						  when dv.Tip = 'N' then 'inchis' 
											else 'de facturat' end) like @filtrutipdeviz
				and (p.Loc_de_munca in (select proprietati.Valoare from proprietati where proprietati.tip='UTILIZATOR' and proprietati.Cod_proprietate='LOCMUNCA' and proprietati.cod=@utilizator) or 
					(isnull ((select proprietati.Valoare from proprietati where proprietati.tip='UTILIZATOR' and proprietati.Cod_proprietate='LOCMUNCA' and proprietati.cod=@utilizator),'')='' and lm.Denumire like '%'+@filtrulm+'%'))
					
				order by data_lansarii desc
for xml raw
end
