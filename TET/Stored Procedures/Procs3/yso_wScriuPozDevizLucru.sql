

CREATE procedure  [dbo].[yso_wScriuPozDevizLucru]  @sesiune varchar(50), @parXML XML
as
declare @sub varchar(9), @par varchar(200), @LIFO int, @devizepemecanici int, @echipemecanici int, 
	@codmanop varchar(20), @stareplaja varchar(200)/*@stareplaja sa ramana varchar(200)*/, @update int, 
	--variabile pentru tabela "devauto"
	@tip char(2), @nrdeviz char(20), @nrinmatriculare char(50), @dataincepere datetime, 
	@oraincepere char(8), @datainchiderii datetime, @autovehicul char(20), @KMbord float, 
	@postlucru char(9), @o_postlucru char(9), 
	@beneficiar char(13), @tipdeviz char(1), @valoaredeviz float, @valoarerealizari float, 
	@sesizareclient char(200), @constatareservice char(200), @obs char(200), @stare varchar(1), 
	@termenexecutie datetime, @oraexecutie char(8),	@nrdosar char(8), @factura char(20), 
	--variabile pentru tabela "pozdevauto"
	@subtip varchar(2), @cod char(20), @o_cod char(20), @pozitiearticol float, @tipresursa char(1), 
	@cantitate float, @o_cantitate float, @timpnormat float, @tarif float, @pretdestoc float, 
	@adaos float, @discount float, @o_discount float, @pretvanzare float, @o_pretvanzare float, 
	@contdestoc char(13), @barcod char(20), @dataplanificata datetime, @oraplanificata char(8), 
	@nrconsum char(8),@datafinalizarii datetime, @orafinalizarii char(8), @locmunca char(9), 
	@gestiune char(9), @o_gestiune char(9), @starepozitie varchar(1), @o_starepozitie varchar(1), 
	@marca char(6), @codintrare char(13),@utilizator char(10),@dataoperarii datetime,@oraoperarii char(8),
	@utilizatorconsum char(10), @utilizatorfacturare char(10), @nraviz char(8),@datafacturarii datetime,
	@promotie char(13), @generatie smallint, @confirmattelefonic bit, --@explicatii char(100), 
	@tertfactrefact char(13), @datafactrefact datetime, @cotaTVA float, @o_cotaTVA float

exec luare_date_par @tip='GE', @par='SUBPRO', @val_l=0, @val_n=0, @val_a=@sub output
exec luare_date_par @tip='GE', @par='LIFO', @val_l=@LIFO output, @val_n=0, @val_a=''
exec luare_date_par @tip='SA', @par='MECANTDEV', @val_l=@devizepemecanici output, @val_n=0, @val_a=''
--exec luare_date_par @tip='DL', @par='ECHIPMEC', @val_l=@echipemecanici output, @val_n=0, @val_a=''
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @update=isnull(@parXML.value('(/row/row/@update)[1]', 'int'), 0)   
--devauto	
set @tip= rtrim(isnull(@parXML.value('(/row/@tip)[1]', 'varchar(10)'), ''))
set @nrdeviz= rtrim(isnull(@parXML.value('(/row/@nrdeviz)[1]', 'varchar(20)'),''))
set @nrinmatriculare= rtrim(isnull(@parXML.value('(/row/@nrinmatriculare)[1]', 'varchar(10)'), ''))
set @sesizareclient= rtrim(isnull(@parXML.value('(/row/@sesizareclient)[1]', 'varchar(200)'), ''))
set @constatareservice= rtrim(isnull(@parXML.value('(/row/@constatareservice)[1]', 'varchar(200)'), ''))
set @KMbord= rtrim(isnull(@parXML.value('(/row/@kmbord)[1]', 'float'), 0))
set @valoaredeviz= @parXML.value('(/row/@valoaredeviz)[1]', 'float') --sa ramana fara isnull
set @valoarerealizari= rtrim(isnull(@parXML.value('(/row/@valoarerealizari)[1]', 'float'), 0))
set @nrdosar= rtrim(isnull(@parXML.value('(/row/@nrdosar)[1]', 'varchar(10)'), ''))
set @postlucru= rtrim(isnull(@parXML.value('(/row/@postlucru)[1]', 'varchar(10)'), ''))
set @o_postlucru= rtrim(isnull(@parXML.value('(/row/@o_postlucru)[1]', 'varchar(10)'), ''))

set @autovehicul= rtrim(isnull(@parXML.value('(/row/@autovehicul)[1]', 'varchar(10)'), ''))
set @beneficiar= (select Cod_proprietar from auto where cod=@autovehicul)--rtrim(isnull(@parXML.value('(/row/@beneficiar)[1]', 'varchar(50)'), ''))
set @obs= rtrim(isnull(@parXML.value('(/row/@obs)[1]', 'varchar(200)'), ''))
set @tipdeviz= rtrim(isnull(@parXML.value('(/row/@tipdeviz)[1]', 'varchar(20)'), ''))
set @factura= rtrim(isnull(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''))
set @stare= rtrim(isnull(@parXML.value('(/row/@stare)[1]', 'varchar(10)'), ''))
if @stare='' set @stare='0'
set	@dataincepere = rtrim(isnull(@parXML.value('(/row/@dataincepere)[1]', 'datetime'), getdate()))
set @oraincepere= rtrim(isnull(@parXML.value('(/row/@oraincepere)[1]', 'varchar(10)'), ''))
if @oraincepere='' set @oraincepere=replace(convert(varchar(10),getdate(),108),':','')
set @termenexecutie= isnull(@parXML.value('(/row/@termenexecutie)[1]','datetime'),@dataincepere)
set @oraexecutie= rtrim(isnull(@parXML.value('(/row/@oraexecutie)[1]', 'varchar(10)'), ''))
if @oraexecutie='' set @oraexecutie=@oraincepere
set @datainchiderii= isnull(@parXML.value('(/row/@datainchiderii)[1]','datetime'),@dataincepere)

--pozdevauto
set	@subtip = rtrim(isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'),''))
set @tipresursa=right(@subtip,1) --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--set @tipresursa = isnull(@parXML.value('(/row/row/@tipresursa)[1]', 'varchar(1)'), '')
set	@pozitiearticol= rtrim(isnull(@parXML.value('(/row/row/@pozitiearticol)[1]', 'float'), 0))
set	@o_gestiune= rtrim(isnull(@parXML.value('(/row/row/@o_gestiune)[1]', 'varchar(50)'), ''))
--Daca nu este configurata citirea campului de gestiune, atunci se ia din parametri
set	@gestiune= rtrim(isnull(@parXML.value('(/row/row/@gestiune)[1]', 'varchar(50)'), ''))
if @tipresursa='P' and @gestiune='' 
	set @gestiune=isnull ((select proprietati.Valoare from proprietati where proprietati.tip='UTILIZATOR' and proprietati.Cod_proprietate='GESTPSERV' and proprietati.cod=@utilizator),'')

set	@barcod= rtrim(isnull(@parXML.value('(/row/row/@barcod)[1]', 'varchar(50)'), ''))
set	@o_cod = isnull(@parXML.value('(/row/row/@o_cod)[1]', 'varchar(20)'), '')
set	@cod = isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), '')
if @barcod<>'' set @cod=ISNULL((select Cod_produs from codbare where Cod_de_bare=@barcod),'')
if @tipresursa='R' and @cod='' set @cod=isnull((select top 1 val_alfanumerica from par where 
	tip_parametru='DL' and parametru='MANR'),'')
set	@timpnormat = rtrim(isnull(@parXML.value('(/row/row/@timpnormat)[1]', 'float'), 0))
if @tipresursa='M' and (@timpnormat=0 or @cod<>@o_cod) 
	begin
		if exists (select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='catop' 
		and sc.name='norma_timp')
			set @timpnormat=ISNULL((select isnull(norma_timp,Numar_persoane) from catop where cod=@cod),0)
		else
			set @timpnormat=ISNULL((select Numar_persoane from catop where cod=@cod),0)
	end
set @tarif= isnull(@parXML.value('(/row/row/@tarif)[1]', 'float'), 0)
if @tipresursa='M' and (@tarif=0) 
	set @tarif=ISNULL((select tarif from catop where cod=@cod),0)
if /*@tarif=-1 and */@tipresursa='P' and (@gestiune<>@o_gestiune or @cod<>@o_cod)
	set @tarif=isnull((select top 1 pret from stocuri where Tip_gestiune not in ('F','T') 
		and Cod_gestiune=@gestiune and cod=@cod and stoc>=0.001 order by subunitate, Tip_gestiune, 
		Cod_gestiune, cod, (case when @LIFO=1 then 1-data else data end), Cod_intrare),0)
set	@pretdestoc = rtrim(isnull(@parXML.value('(/row/row/@pretdestoc)[1]', 'float'), 0))
set	@adaos = rtrim(isnull(@parXML.value('(/row/row/@adaos)[1]', 'float'), 0))
set	@o_discount = rtrim(isnull(@parXML.value('(/row/row/@o_discount)[1]', 'float'), 0))
set	@discount = rtrim(isnull(@parXML.value('(/row/row/@discount)[1]', 'float'), 0))
set	@contdestoc = rtrim(isnull(@parXML.value('(/row/row/@contdestoc)[1]', 'varchar(50)'), ''))
set	@dataplanificata = rtrim(isnull(@parXML.value('(/row/row/@dataplanificata)[1]', 'datetime'), @dataincepere))
set	@oraplanificata = rtrim(isnull(@parXML.value('(/row/row/@oraplanificata)[1]', 'varchar(50)'), '000000'))
set	@nrconsum = rtrim(isnull(@parXML.value('(/row/row/@nrconsum)[1]', 'varchar(50)'), ''))
set	@datafinalizarii = rtrim(isnull(@parXML.value('(/row/row/@datafinalizarii)[1]', 'datetime'), 
	convert(datetime,convert(char(10),getdate(),104),104)))
set	@orafinalizarii = rtrim(isnull(@parXML.value('(/row/row/@orafinalizarii)[1]', 'varchar(50)'), '000000'))
set	@o_starepozitie = rtrim(isnull(@parXML.value('(/row/row/@o_starepozitie)[1]', 'varchar(50)'), ''))
set	@starepozitie = rtrim(isnull(@parXML.value('(/row/row/@starepozitie)[1]', 'varchar(50)'), ''))
if @starepozitie='' and @factura<>'' 
begin
	set @par='PDEV'+RTRIM(@factura)
	exec luare_date_par @tip='SA', @par=@par, @val_l=0, @val_n=0, @val_a=@stareplaja output
	set @stareplaja=isnull(SUBSTRING(@stareplaja,61,1),'')
end
if @starepozitie='' set @starepozitie=(case when @tipresursa in ('R','S','A') then '2' 
	when isnull(@stareplaja,'')<>'' then isnull(@stareplaja,'') else '1' end)
set	@locmunca = @parXML.value('(/row/row/@locmunca)[1]', 'varchar(50)')
if (@locmunca is null or @postlucru<>@o_postlucru)
	set @locmunca=isnull((case when @devizepemecanici=1 then (select Loc_de_munca from personal where 
	Marca=@postlucru) else (select Loc_de_munca from Posturi_de_lucru where Postul_de_lucru=@postlucru) 
	end),'')
set	@marca = rtrim(isnull(@parXML.value('(/row/row/@marca)[1]', 'varchar(50)'), ''))
--if @echipemecanici=1 and @tipdeviz not in ('B','N') --@echipemecanici citit din par e comentat sus
if @marca='' set @marca=(case when @update=0 and @tipresursa not in ('R','S') then 
	(case /*when @echipemecanici=1 and @nrmecanici<>0 then @marcasefpostlucru */when @devizepemecanici=1 
	then LEFT(@postlucru,6) else @marca end) when @tipresursa not in ('R','S') then @marca else '' end)
set	@codintrare = rtrim(isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(50)'), ''))

set	@utilizatorconsum= rtrim(isnull(@parXML.value('(/row/row/@utilizatorconsum)[1]', 'varchar(50)'), ''))
set	@utilizatorfacturare = rtrim(isnull(@parXML.value('(/row/row/@utilizatorfacturare)[1]', 'varchar(50)'), ''))
set	@nraviz = rtrim(isnull(@parXML.value('(/row/row/@nraviz)[1]', 'varchar(50)'), ''))
set	@datafacturarii = rtrim(isnull(@parXML.value('(/row/row/@datafacturarii)[1]', 'datetime'), '01/01/1901'))
set	@promotie = rtrim(isnull(@parXML.value('(/row/row/@promotie)[1]', 'varchar(50)'), ''))
set	@generatie = rtrim(isnull(@parXML.value('(/row/row/@generatie)[1]', 'smallint'), 0))
if @update=0 and @generatie=0 set @generatie=ISNULL((select top 1 generatie from pozdevauto where 
	Cod_deviz=@nrdeviz order by Cod_deviz, generatie desc),0)
set	@confirmattelefonic = rtrim(isnull(@parXML.value('(/row/row/@confirmattelefonic)[1]', 'bit'), 0))
set	@tertfactrefact = rtrim(isnull(@parXML.value('(/row/row/@tertfactrefact)[1]', 'varchar(50)'), ''))
set	@datafactrefact = rtrim(isnull(@parXML.value('(/row/row/@datafactrefact)[1]', 'datetime'), '01/01/1901'))
set	@o_cantitate= rtrim(isnull(@parXML.value('(/row/row/@o_cantitate)[1]', 'float'), 0))
set	@cantitate= rtrim(isnull(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0))
if @tipresursa in ('M','A','R','S') and @cantitate=0 set @cantitate=1
set	@pretvanzare = rtrim(isnull(@parXML.value('(/row/row/@pretvanzare)[1]', 'float'), 0))
set @o_pretvanzare = rtrim(isnull(@parXML.value('(/row/row/@o_pretvanzare)[1]', 'float'), @pretvanzare))
if @tipresursa in ('M') set @pretvanzare=ROUND(@tarif*@timpnormat,5)
if @tipresursa in ('P','S') and (@pretvanzare=0 or @pretvanzare=0 and @cod<>@o_cod) 
	set @pretvanzare=isnull((select top 1 Pret_vanzare from preturi where Cod_produs=@cod and um=1 and 
	Tip_pret='1' and Data_inferioara<=getdate() and Data_superioara>=getdate() order by Cod_produs, um, 
	Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii),0)*
	(case when ISNULL((select valuta from nomencl where cod=@cod),'')<>'' 
	and isnull((select In_valuta from categpret where Categorie=1),0)=1 
	then isnull((select top 1 curs from curs where valuta=(select valuta from nomencl where cod=@cod) 
	and data<=getdate() order by valuta, data desc),0) else 1 end)
set	@cotaTVA = isnull(@parXML.value('(/row/row/@cotaTVA)[1]', 'float'), -1)
set	@o_cotaTVA = isnull(@parXML.value('(/row/row/@o_cotaTVA)[1]', 'float'), (case when @cotaTVA=-1 
	then 0 else @cotaTVA end))
if @tipresursa not in ('M','P','R','S') set @cotaTVA=0
if @tipresursa in ('P','R','S') and (@cotaTVA = -1 or @cod<>@o_cod)
	set @cotaTVA=isnull((select Cota_TVA from nomencl where cod=@cod),0)
if @tipresursa='M' and @cotaTVA = -1
begin
	exec luare_date_par @tip='DL', @par='CODMANOP', @val_l=0,  @val_n=0, @val_a=@codmanop output
	if @cotaTVA = -1 set @cotaTVA=(select Cota_TVA from nomencl where cod=@codmanop)
	if isnull(@cotaTVA,-1) = -1
	begin
		set @cotaTVA=null
		exec luare_date_par @tip='GE', @par='COTATVA', @val_l=0, @val_n=@cotaTVA output, @val_a=''
	end
end

if isnull(@nrdeviz, '')=''
begin
	raiserror('Nr. deviz necompletat!',11,1)
	return -1
end

if @valoaredeviz is null and @update=0 and exists (select 1 from devauto where Cod_deviz=@nrdeviz)
begin
	raiserror('Nr. deviz existent!',11,1)
	return -1
end

if not exists (select 1 from auto where cod=@autovehicul)
begin
	raiserror('Autovehicul inexistent!',11,1)
	return -1
end

if not exists (select 1 from terti where tert=@beneficiar)
begin
	raiserror('Beneficiar inexistent!',11,1)
	return -1
end

if @termenexecutie<@dataincepere
begin
	raiserror('Termenul de executie trebuie sa fie mai mare decat data incepere!',11,1)
	return -1
end

if @devizepemecanici=0 and not exists (select 1 from Posturi_de_lucru where Postul_de_lucru=convert(float,@postlucru))
begin
	raiserror('Post de lucru inexistent!',11,1)
	return -1
end

if @devizepemecanici=1 and not exists (select 1 from personal where Marca=@postlucru)
begin
	raiserror('Mecanic inexistent!',11,1)
	return -1
end

if @update=1 and isnull(@cod,'')<>@o_cod and not (((@starepozitie<'2' and @tipresursa not in 
('R','S','A') or @starepozitie<='2' and @tipresursa in ('R','S','A')) and @tipresursa in 
('P','M','R','S') or @tipresursa='G' or @tipresursa='A') and @promotie='')
begin
		raiserror('Nu este permisa schimbarea codului pe o astfel de pozitie!',11,1)
		return
end

/*if @update=0 and exists (select 1 from pozdevauto where Tip_resursa=@tipresursa and Cod=@cod)
begin
	raiserror('Cod existent deja cu acest tip pe acest deviz!',11,1)
	return -1
end
*/
if @tipresursa='P' and not exists (select 1 from nomencl where tip not in ('R','S','F','O') and cod=@cod)
begin
	raiserror('Cod inexistent sau cu tip de nomenclator R/S/F/O, tip nepermis pt. a fi introdus ca piesa!',11,1)
	return -1
end

if @tipresursa in ('R','S') and not exists (select 1 from nomencl where tip='S' and cod=@cod)
begin
	raiserror('Serviciu (prestat) inexistent!',11,1)
	return -1
end

if @tipresursa='G' and not exists (select 1 from grupe where Grupa=@cod)
begin
	raiserror('Grupa de resurse inexistenta!',11,1)
	return -1
end

if @tipresursa='A' and not exists (select 1 from auto where cod=@cod)
begin
	raiserror('Autovehicul / accesoriu inexistent!',11,1)
	return -1
end

if @tipresursa not in ('M','S','R') and @cantitate < 0 or @cantitate=0
begin
	raiserror('Cantitate incorecta!',11,1)
	return -1
end

if @tipresursa='M' and @timpnormat <= 0
begin
	raiserror('Nu sunt permise valori negative sau nule la timp normat!',11,1)
	return -1
end

if @tipresursa<>'A' and @pretvanzare <= 0
begin
	raiserror('Nu sunt permise valori negative sau nule la pret vanzare!',11,1)
	return -1
end

if (@tipresursa='M' or @marca<>'') and not exists (select 1 from personal where Marca=@marca)
begin
	raiserror('Marca inexistenta!',11,1)
	return -1
end

if (@tipresursa='R' and @tertfactrefact<>'') and not exists (select 1 from terti where tert=@tertfactrefact)
begin
	raiserror('Tert inexistent!',11,1)
	return -1
end

if @tipresursa='P' and not exists (select 1 from gestiuni where Cod_gestiune=@gestiune)
begin
	raiserror('Gestiune de transfer in service neconfigurata!',11,1)
	return -1
end

if isnull(@nrdeviz, '')=''
begin
	declare @NrDocFisc int, @fXML xml, @tipPentruNr varchar(2)
	set @tipPentruNr='AP'
	set @fXML = '<row/>'
	--tip=DL neaparat
	set @fXML.modify ('insert attribute tipmacheta {"AP"} into (/row)[1]')
	set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
	set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
	set @fXML.modify ('insert attribute lm {sql:variable("@locmunca")} into (/row)[1]')
				
	exec wIauNrDocFiscale @parXML=@fXML, @numar=@NrDocFisc output
	
	if ISNULL(@NrDocFisc, 0)<>0 set @nrdeviz=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
end

if @update=0 --and @subtip in M-Manopera, P-Piese, R-Refacturare, S-Servicii, G-Grupe de piese, A-Autovehicul
begin
		if not exists (select 1 from devauto where cod_deviz=@nrdeviz /*and denumire_deviz=@nrinmatriculare*/)
		begin
					insert into devauto 
						(Cod_deviz,Denumire_deviz,Data_lansarii,Ora_lansarii,Data_inchiderii,
						Autovehicul, KM_bord, Executant,Beneficiar,Valoare_deviz,Valoare_realizari,
						Sesizare_client,Constatare_service,Observatii, Stare,
						Termen_de_executie, Ora_executie,Numar_de_dosar,Tip, Factura)
						values 
						(@nrdeviz, @nrinmatriculare, @dataincepere, @oraincepere, @datainchiderii, 
						@autovehicul, @KMbord, @postlucru, @beneficiar, isnull(@valoaredeviz,0), 
						@valoarerealizari, @sesizareclient, @constatareservice, @obs, @stare, 
						@termenexecutie, @oraexecutie, @nrdosar, @tipdeviz, @factura)
		end
		if not exists (select 1 from comenzi where Comanda=@nrdeviz)
		begin
					insert into comenzi
						(Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, 
						Starea_comenzii, Grup_de_comenzi, Loc_de_munca, Numar_de_inventar, 
						Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef)
						values 
						(@sub, @nrdeviz, '', 'Deviz '+@nrdeviz, @dataincepere, @datainchiderii, 
						'L', 0, '', '', '', '', '', '')
		end
		/*if @tipresursa='P'
		begin
			if @pretvanzare=0
			begin
				declare @dXML xml
				set @dXML = '<row/>'
				set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
				set @dXML.modify ('insert attribute tert {sql:variable("@beneficiar")} into (/row)[1]')
				set @dXML.modify ('insert attribute data {sql:variable("@dataincepere")} into (/row)[1]')
				declare @dstr char(10)
				set @dstr=convert(char(10),@dataincepere,101)											
				if @pretvanzare=0 set @pretvanzare=null
				  exec wIaPretDiscount @dXML, @pretvanzare output, @discount output										
			end
		end
		
		select @pretvanzare=isnull(@pretvanzare, 0), @discount=isnull(@discount, 0)
		--if isnull(@nrdeviz,'')<> '' set  @tip='D' --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		--pentru manopera se pune tariful din tabela "catop" in pret vanzare
		if @tipresursa='M' and @pretvanzare=0 set @pretvanzare=isnull((select top 1 tarif from catop 
			where cod=@cod/*@codtarif*/),0)*/
		select @pozitiearticol=1+isnull((select max(pozitie_articol) from pozdevauto where 
			cod_deviz=@nrdeviz),0)
								
		if not exists(select 1 from pozdevauto where tip_resursa=@tipresursa and cod_deviz=@nrdeviz 
			and cod=@cod and pozitie_articol=@pozitiearticol and tip='D')
			begin 
				insert into pozdevauto 
				(Tip, Cod_deviz,Pozitie_articol,Tip_resursa,Cod,Cantitate,Timp_normat,Tarif_orar,
				Pret_de_stoc,Adaos,Discount,Pret_vanzare,Cont_de_stoc,Cod_corespondent,Data_lansarii,
				Ora_planificata,Numar_consum, Data_finalizarii,Ora_finalizarii,Cod_gestiune,Stare_pozitie,
				Loc_de_munca,Marca,Cod_intrare,Utilizator,Data_operarii,Ora_operarii,Utilizator_consum,
				Utilizator_facturare,Numar_aviz,Data_facturarii,Promotie,Generatie,Confirmat_telefonic,
				Explicatii,Cota_TVA)
				values --tb. facut la fel si-n update-ul de mai jos
				('D'/*@tip*/, @nrdeviz, @pozitiearticol, @tipresursa, @cod,	@cantitate, @timpnormat, 
				@tarif, @pretdestoc, @adaos, @discount, @pretvanzare, @contdestoc, @barcod,
				@dataplanificata, @oraplanificata, @nrconsum, @datafinalizarii, @orafinalizarii, 
				@gestiune, @starepozitie, @locmunca, @marca, @codintrare, @utilizator,
				convert(datetime,convert(char(10),getdate(),104),104), 
				RTrim(replace(convert(char(8),getdate(),108),':','')), @utilizatorconsum, 
				@utilizatorfacturare, @nraviz, @datafacturarii, @promotie, @generatie, 
				@confirmattelefonic, (case when @tipresursa='R' 
				then convert(char(10),@datafactrefact,103)+@tertfactrefact else '' end), @cotaTVA)
				--tb. facut la fel si-n update-ul de mai jos
			end	
			else 
				raiserror('Exista deja o astfel de pozitie pe acest deviz! Incercati din nou!',16,1)
	    --end																																										
end

update devauto set Valoare_deviz=Valoare_deviz+convert(decimal(17,2),round(@cantitate*
	@pretvanzare*(1.00-@discount/100)*(1.00+@cotaTVA/100),3))-convert(decimal(17,2),round(@o_cantitate*
	@o_pretvanzare*(1.00-@o_discount/100)*(1.00+@o_cotaTVA/100),3))
	where Cod_deviz=@nrdeviz

--modificare date 
if @update=1 --and @subtip in ('M','P')
begin
	update pozdevauto set cod=@cod, cantitate=@cantitate, Timp_normat=@timpnormat, Tarif_orar=@tarif, 
		Pret_de_stoc=@pretdestoc, Adaos=@adaos, Discount=@discount, pret_vanzare=@pretvanzare, 
		Cont_de_stoc=@contdestoc, Cod_corespondent=@barcod, Data_lansarii=@dataplanificata,
		Ora_planificata=@oraplanificata, Numar_consum=@nrconsum, Data_finalizarii=@datafinalizarii, 
		Ora_finalizarii=@orafinalizarii, Cod_gestiune=@gestiune, Stare_pozitie=@starepozitie,
		Loc_de_munca=@locmunca, Marca=@marca, Cod_intrare=@codintrare, Utilizator=@utilizator,
		Data_operarii=convert(datetime,convert(char(10),getdate(),104),104),
		Ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':','')), 
		Utilizator_consum=@utilizatorconsum, Utilizator_facturare=@utilizatorfacturare, 
		Numar_aviz=@nraviz, Data_facturarii=@datafacturarii, Promotie=@promotie, Generatie=@generatie, 
		Confirmat_telefonic=@confirmattelefonic, Explicatii=(case when @tipresursa='R' then 
		convert(char(10),@datafactrefact,103)+@tertfactrefact else '' end), Cota_TVA=@cotaTVA
		WHERE Cod_deviz=@nrdeviz --mai jos  a fost /row/linie/!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		and tip='D' --rtrim(isnull(@parXML.value('(/row/row/@tip)[1]', 'varchar(10)'), '')) 
		and Pozitie_articol=isnull(@parXML.value('(/row/row/@pozitiearticol)[1]', 'float'), 0)
		and Tip_resursa=rtrim(isnull(@parXML.value('(/row/row/@tipresursa)[1]', 'varchar(10)'), ''))
		and Cod=rtrim(isnull(@parXML.value('(/row/row/@o_cod)[1]', 'varchar(20)'), ''))
end

if @starepozitie<>@o_starepozitie --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
begin
	UPDATE devauto set Stare=isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz=@nrdeviz 
		/*and Pozitie_articol<>@pozitiearticol*/),stare) 
		WHERE Cod_deviz=@nrdeviz
end

declare @docXMLIaPozDevizLucru xml
set @docXMLIaPozDevizLucru ='<row nrdeviz="'+rtrim(@nrdeviz)+'"/>'
exec wIaPozDevizLucru @sesiune=@sesiune, @parXML=@docXMLIaPozDevizLucru

