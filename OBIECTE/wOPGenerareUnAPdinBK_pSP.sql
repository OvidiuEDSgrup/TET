--***
if exists (select * from sysobjects where name ='wOPGenerareUnAPdinBK_pSP')
	drop procedure wOPGenerareUnAPdinBK_pSP
go


create procedure wOPGenerareUnAPdinBK_pSP @sesiune varchar(50), @parXML xml OUTPUT
as  

begin try

	declare @contract varchar(20),@mesaj varchar(500),@tip varchar(2), @subtip varchar(2),@tert varchar(13),@data datetime,@sub varchar(9),
		@gestiune varchar(20),@gestprim varchar(20),@categPret varchar(13),@numarDoc varchar(13), @dataDoc varchar(10),@tipDoc varchar(2),
		@utilizator varchar(20),@stare int, @dentert varchar(200)
		, @numedelegat varchar(200), @nrformular varchar(10), @denformular varchar(100), @iddelegat varchar(10), @prenumedelegat varchar(100)
		, @nrmijltransp varchar(13),@serieCI varchar(50), @numarCI varchar(50), @eliberatCI varchar(50), @observatii varchar(200)
		, @mijloctp varchar(50), @denmijloctp varchar(200), @modPlata varchar(50)

	select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@contract=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@tert=upper(ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@stare=upper(ISNULL(@parXML.value('(/row/@stare)[1]', 'int'), 0)),
		@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
		@gestprim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(20)'), ''),
		@tipDoc='TE'

--/*SP
	declare @MULTICDBK int
	declare @cComAprov char(20), @dAprov datetime, @cFurn char(13), @cCod char(20), @nCantReceptie float, 
		@cTip char(2), @cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantReceptionata float, 
		@nCantDescarc float, @nCantRealizBK float, @nCantRealizata float,
		@cComProd char(20),@nCantPredare float,@nCantLivrata float 	
	declare @stareAprobatBK varchar(1),@stareRealizatBK varchar(1),@stareTransferatBK varchar(1),@stareFacturabilBK varchar(1),
		@stareBlocatBK varchar(1), @stareInchisBK varchar(1),@realBFdinBKapob int

	--luare date din par
	select @sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),
		--@TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0),
		@MULTICDBK=isnull((case when Parametru='MULTICDBK' and Tip_parametru='UC' then Val_logica else @MULTICDBK end),0),
		@stareRealizatBK=isnull((case when Parametru='STBKREAL' and Tip_parametru='UC' then Val_alfanumerica else @stareRealizatBK end),'6'),
		@stareTransferatBK=isnull((case when Parametru='STBKTRANS' and Tip_parametru='UC' then Val_alfanumerica else @stareTransferatBK end),'4'),
		@stareFacturabilBK=isnull((case when Parametru='STBKFACT' and Tip_parametru='UC' then Val_alfanumerica else @stareFacturabilBK end),'1'),
		@stareAprobatBK=isnull((case when Parametru='STBKAPROB' and Tip_parametru='UC' then Val_alfanumerica else @stareAprobatBK end),'1'),
		@stareBlocatBK=isnull((case when Parametru='STBKBLOC' and Tip_parametru='UC' then Val_alfanumerica else @stareBlocatBK end),'2'),
		@stareInchisBK=isnull((case when Parametru='STBKINCH' and Tip_parametru='UC' then Val_alfanumerica else @stareInchisBK end),'7'),
		@realBFdinBKapob=isnull((case when Parametru='RBFBKAPR' and Tip_parametru='UC' then Val_logica else @realBFdinBKapob end),0)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('POZSURSE','MULTICDBK'))
--SP*/

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati     

	if ISNULL(@tert,'')=''
		select '    Pentru facturare, pe comanda de livrare trebuie sa fie definit beneficiarul!' 
			as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')	
		
	select	@nrformular=(case when p.Cod_proprietate='UltFormGenAPBK' then rtrim(p.Valoare) else isnull(@nrformular,'') end)
	from proprietati p
	where p.Tip='PROPUTILIZ' and p.Cod=@utilizator and p.Valoare_tupla=''
		and P.Cod_proprietate in ('UltFormGenAPBK')
	
	select @iddelegat=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@Tert and p.cod_proprietate='UltDelegat' and p.Valoare<>''
	select @nrmijltransp=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@tert and p.cod_proprietate='UltMasina' and p.Valoare<>''
	select @modPlata=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@tert and p.cod_proprietate='UltModPlataAPBK' and p.Valoare<>''
	
	select	@dentert=RTRIM(t.Denumire)
		, @numeDelegat = c.Pers_contact+SPACE(50)+c.Nume_delegat+convert(char(3),dbo.fStrToken(c.buletin, 1, ','))+convert(char(9),dbo.fStrToken(c.buletin, 2, ','))+c.eliberat--rtrim(isnull(c.Descriere,i.Nume_delegat))
		, @prenumedelegat = rtrim(c.Nume_delegat)
		, @serieCI = dbo.fStrToken(c.buletin, 1, ','), @numarCI = dbo.fStrToken(c.buletin, 2, ','), @eliberatCI = RTRIM(c.eliberat)
	from terti t 
		left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
		left join infotert c on c.Subunitate='C'+t.Subunitate and c.Tert=t.Tert and c.Identificator=@idDelegat
	where t.Subunitate=@sub and t.tert=@tert 
	
	select @mijloctp=rtrim(m.Descriere) , @denmijloctp=convert(char(10),m.Numarul_mijlocului)+space(50)+convert(char(30),m.Descriere) 
	from masinexp m where m.Numarul_mijlocului=@nrmijltransp --and m.Furnizor=@tert
		
	select @denformular=RTRIM(f.Denumire_formular)
	FROM antform f
	WHERE f.Numar_formular=@nrformular
	
	select @numardoc=rtrim(c.Factura), @datadoc=convert(varchar,f.Data,101) 
	from con c 
		left join facturi f on f.Subunitate=c.Subunitate and f.Tip=0x46 and f.Tert=c.Tert and f.Factura=c.Factura and f.Factura<>''
	where c.Subunitate=@sub and c.Tip=@tip and c.Data=@data and c.Contract=@contract and c.Tert=@tert
	
	SELECT rtrim(@tert) as beneficiar, @tert+ ' - ' +rtrim(@dentert)  as denbenef, @numardoc AS numardoc, @datadoc AS datadoc
		, iddelegat=isnull(@iddelegat,''), isnull(@numedelegat,@utilizator) numedelegat, isnull(@prenumedelegat,'') prenumedelegat
		, isnull(@nrmijltransp,rtrim(dbo.wfProprietateUtilizator('NrAuto',@utilizator))) nrmijltransp, @denmijloctp denmijloctp, @mijloctp mijloctp
		, isnull(@serieCI,dbo.wfProprietateUtilizator('SerieCI',@utilizator)) seriebuletin
		, isnull(@numarCI,rtrim(dbo.wfProprietateUtilizator('NumarCI',@utilizator))) numarbuletin
		, isnull(@eliberatCI,rtrim(dbo.wfProprietateUtilizator('EliberatCI',@utilizator))) eliberatbuletin	
		, observatii=@observatii
		, data_expedierii=convert(varchar,GETDATE(),101), ora_expedierii=left(convert(varchar,getdate(),114),8)
		, modPlata=@modPlata
		, nrformular=@nrformular, denformular=@denformular
	FOR XML raw, root('Date')

	SELECT (    
		select rtrim(p.cod) as cod, 
			--> in transfer se va duce cantitatea aprobata ramasa netransferata(Pret_promotional->camp refolosit pentru cant. transferata)
			convert(decimal(15,3),(p.cantitate-p.cant_realizata)) as cantitate_factura,
			convert(decimal(15,3),(p.cant_aprobata-p.cant_realizata)) as cantitate_disponibila, 
			gestiune= COALESCE(NULLIF(@gestprim,''), @gestiune), /*
			(case 			
				(case 
					when not (abs(p.cant_aprobata)>=0.001)
					then '0' --nu exista nici o pozitie aprobata
					when not (abs(p.cant_aprobata)-abs(p.cant_realizata)>=0.001 
							or abs(p.cant_aprobata)>=0.001 and sign(p.cant_aprobata)*sign(p.cant_realizata)<1) 
					then (case when p.tip in ('BK', 'BP') then @stareRealizatBK else '6' end) --realizat
					when p.tip='BK' and not (abs(p.cant_aprobata)-abs(p.pret_promotional)>=0.001 
							or abs(p.cant_aprobata)>=0.001 and sign(p.cant_aprobata)*sign(p.pret_promotional)<1)
					then (case when p.tip in ('BK', 'BP') then @stareTransferatBK else '4' end) --expediat/transferat
					when p.tip in ('BK', 'BP') 
					then (case @stare when @stareRealizatBK then @stareFacturabilBK when @stareTransferatBK then @stareAprobatBK else @stare end)
					else @stare -- nerealizat, neexpediat => Operat sau Definitiv
				end)
			when '1' then @gestiune when '4' then @gestprim else @gestiune end),*/
			-->pretul cu amnuntul se ia din dreptul categoriei de pret
			--isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and um=@CategPret 
			--	order by data_inferioara desc)),0) as pamanunt,
			rtrim(n.Denumire) as denumire, convert(decimal(15,3),p.Cant_aprobata) as cant_aprobata, convert(decimal(15,3),p.cant_realizata) as cant_realizata,
			RTRIM(p.Subunitate) as subunitate,RTRIM(p.tip) as tip, convert(varchar(10),p.data,101)as data, RTRIM(p.Contract) as contract, RTRIM(p.Tert) as tert,
			Numar_pozitie as numar_pozitie	
		from pozcon p
			left outer join nomencl n on p.Cod=n.Cod 
		where p.Subunitate=@sub and p.tip='BK' 
			and p.contract=@contract and (p.tert='' or p.tert=@tert) and p.data=@data
	  FOR XML raw, type  
	  )  
	FOR XML path('DateGrid'), root('Mesaje')

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch