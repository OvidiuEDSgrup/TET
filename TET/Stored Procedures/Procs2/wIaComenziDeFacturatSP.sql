--***
create procedure wIaComenziDeFacturatSP @sesiune varchar(50), @parXML xml 
as  
set transaction isolation level read uncommitted/*sp
if exists(select * from sysobjects where name='wIaComenziDeFacturatSP' and type='P')
begin
	exec wIaComenziDeFacturatSP @sesiune=@sesiune, @parXML=@parXML 
	return 0
end sp*/

begin try
	declare @subunitate varchar(20), @userASiS varchar(20), @filtreazaGestiuni bit, @filtreazaClienti bit, @filtreazaLM bit,
			@tert varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	if @userASiS is null
		return -1
	declare @filtru varchar(80),@starebkfact varchar(2), @xmlString varchar(max)

	select @filtreazaGestiuni=0, @filtreazaClienti=0, @filtreazaLM=0
	select @filtreazaGestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @filtreazaGestiuni end), 
		@filtreazaClienti=(case when cod_proprietate='CLIENT' then 1 else @filtreazaClienti end), 
		@filtreazaLM=(case when cod_proprietate='LOCMUNCA' then 1 else @filtreazaLM end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA') and valoare<>''

	exec luare_date_par @tip='GE', @par='SUBPRO', @val_l=null, @val_n=null, @val_a=@subunitate output
	exec luare_date_par @tip='UC', @par='STBKFACT', @val_l=null, @val_n=null, @val_a=@starebkfact output

	set @tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(80)'),'')
	-- filtrul se trimitea in @filtru pana la PV2.3.005b, dar de atunci se trimite in @searchText, si se trimit datele de antet document.
	set @filtru= isnull(@parXML.value('(/row/@searchText)[1]','varchar(80)'), 
					isnull(@parXML.value('(/row/@filtru)[1]','varchar(80)'),'')) 
	-- adaug '%' pt ca se foloseste doar in cautari
	set @filtru= '%' + @filtru + '%'
	set @xmlString=''
	
	declare @CBENEFAV varchar(13),-->Cont beneficiari pt. avans
		@CODAVBEN varchar(13)-->Codul din nomenclator care se va folosi pentru avans beneficiar(419)
	
	exec luare_date_par @tip='PV', @par='CBENEFAV', @val_l=null, @val_n=null, @val_a=@CBENEFAV output
	exec luare_date_par @tip='PV', @par='CODAVBEN', @val_l=null, @val_n=null, @val_a=@CODAVBEN output
	
	-- caut avansuri doar daca e configurat codul de avans, si e ales tertul, altfel e inutil...
	if len(@CODAVBEN)>0 and len(@tert)>0
		-- inserare avansuri
		set @xmlString=@xmlString+ISNULL( 
			(select /*sp top 100 sp*/
					rtrim(fa.tert) as tert,
					convert(char(10),fa.data,103) as data,
					rtrim(fa.Factura)+' din '+convert(char(10),fa.data,103)+'-'+rtrim(t.Denumire) as explicatii,
					-- atribute hardcodate PV
					@CODAVBEN as cod,
					rtrim(n.Denumire) as denumire,
					(case when fa.Sold<0 then -1 else 1 end) as cantitate,
					rtrim(n.UM) as um,
					LTRIM(CONVERT(decimal(12,2),-fa.Sold)) as pretcatalog,
					0 as discount,
					n.cota_tva as cotatva,
					-- end atribute hardcodate PV
					LTRIM(CONVERT(decimal(12,2),-fa.Sold)) as pret,
					LTRIM(CONVERT(decimal(12,2),fa.sold)) as valoare
				from facturi fa
				inner join terti t on t.subunitate=@subunitate and t.tert=@tert and t.Tert=fa.tert				
				inner join nomencl n on n.cod=@CODAVBEN
				where fa.Subunitate=@subunitate and fa.tip=0x46
					and ABS(fa.sold)>0.1 and rtrim(fa.Cont_de_tert)=@CBENEFAV
				order by fa.Data desc
				for xml raw
			)+CHAR(13),'')
		
	-- inserare comenzi de livrare.
	set @xmlString=@xmlString+ISNULL( 
		(select /*sp top 100 sp*/ 
				rtrim(d.Contract) as contract, convert(char(10), d.data,101) as data, rtrim(d.Punct_livrare) as punctLivrare, rtrim(d.tert) as tert,
				--comanda=RTRIM(d.contract),
				rtrim(d.Contract)+'-'+isnull(rtrim(t.Denumire),rtrim(d.Explicatii)) as explicatii,
				-- atribute hardcodate PV
				rtrim(pc.Cod) as cod, rtrim(n.Denumire) as denumire, 
/*sp			(case when ROUND(pc.Cantitate,0)=CONVERT(decimal(12,3),pc.cantitate) then ltrim(str(pc.cantitate))
						else LTRIM(CONVERT(decimal(12,3),cantitate)) end) as cantitate, rtrim(n.UM) as um, sp*/
/*sp */			(case when ROUND(pc.cantitate-pc.Cant_realizata-(case when pc.Punct_livrare like '700%' then pc.Pret_promotional else 0 end),0)=CONVERT(decimal(12,3),pc.cantitate-dbo.valoare_maxima(pc.Pret_promotional,pc.Cant_realizata,0)) then ltrim(str(pc.cantitate-dbo.valoare_maxima(pc.Pret_promotional,pc.Cant_realizata,0)))
						else LTRIM(CONVERT(decimal(12,3),pc.cantitate-pc.Cant_realizata-(case when pc.Punct_livrare like '700%' then pc.Pret_promotional else 0 end))) end) as cantitate
				, rtrim(n.UM) as um,/* sp*/
/*sp
				CONVERT(decimal(12,2),pc.pret--*(1-pc.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100)
					*(1+(pc.cota_tva-case when gp.tip_gestiune in ('A','V') then pc.cota_tva else 0 end)/100)) as pretcatalog,
--sp*/			
--/*sp
				round(CONVERT(decimal(12,2),pc.pret)*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00),2) as pretcatalog,
--sp*/			CONVERT(decimal(12,2),pc.pret*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00)) as pretcatalog,
				convert(int, pc.Cota_TVA) as cotatva, convert(decimal(12,2),pc.Discount) as discount,
				-- end atribute hardcodate PV
				rtrim(d.Loc_de_munca) as lm, 
				--RTRIM(case d.Stare when @starebkfact then pc.Factura else pc.Punct_livrare end) as gestiune, 
/*sp
				CONVERT(decimal(12,2),pc.pret*(1-pc.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100)
					*(1+(pc.cota_tva-case when gp.tip_gestiune in ('A','V') then pc.cota_tva else 0 end)/100)) as pret,
--sp*/			
--/*sp
				round(CONVERT(decimal(12,2),pc.pret)*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00),2) as pret,
--sp*/			CONVERT(decimal(12,2),pc.pret*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00)) as pret,
/*sp
				CONVERT(decimal(12,2),(pc.cantitate-dbo.valoare_maxima(pc.Pret_promotional,pc.Cant_realizata,0))
					*pc.pret*(1-pc.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100)
					*(1+(pc.cota_tva-case when gp.tip_gestiune in ('A','V') then pc.cota_tva else 0 end)/100)) as valoare
--sp*/			
--/*sp
				round(CONVERT(decimal(12,2),pc.cantitate)*CONVERT(decimal(12,2),pc.pret)*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00),2) as valoare
--sp*/			CONVERT(decimal(12,2),pc.cantitate*pc.pret*(1+convert(decimal(12,2),pc.Cota_TVA)/100.00)) as valoare
			from pozcon pc 
			inner join con d on d.Subunitate=pc.Subunitate and pc.tip=d.Tip and d.Contract=pc.Contract 
				and d.Tert=pc.Tert  and d.Data=pc.Data
			inner join nomencl n on pc.Cod=n.Cod
			left outer join terti t on t.subunitate = d.subunitate and t.tert = d.tert 
			left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=pc.Tip and pe.Contract=pc.Contract and pe.Tert=pc.Tert 
				and pe.Data=pc.Data and pe.Cod=pc.Cod      
			left outer join gestiuni gp on gp.cod_gestiune = pc.Punct_livrare
			where 
			d.subunitate=@subunitate and d.tip = 'BK' 
			and (d.Stare /*sp */ = @starebkfact or d.Stare='4' and d.Cod_dobanda not like '700%' )/* sp*/
			and (@tert='' or	t.Tert=@tert)
			and isnull(t.denumire, '')+d.Contract like @filtru 
--/*sp		
			and abs(pc.cantitate-pc.Cant_realizata-(case when pc.Punct_livrare like '700%' then pc.Pret_promotional else 0 end))>=0.001 --sp*/
			order by  patindex(@filtru,isnull(t.denumire, '')+d.Contract), d.data desc
			for xml raw
		)+CHAR(13),'')
	if @sesiune='' select @tert,@xmlString
	if exists (select 1 from sysobjects where name='pozdevauto') 
	begin
		declare @codManopera varchar(200)
		exec luare_date_par @tip='DL', @par= 'CODMANOP', @val_l = null, @val_n =null, @val_a = @codManopera output
		
		-- tabela in care pregatesc datele de trimis.
		declare @devize table (id int identity, tert varchar(50), explicatii varchar(200), lm varchar(20),
			codDeviz varchar(20), pozitieDeviz int,	-- campuri pentru devize
			cod varchar(20), denumire varchar(80), cantitate decimal(12,3), cantitateMinima decimal(12,3), um varchar(3), 
			pret decimal(12,2), valoare decimal(12,2), gestiune varchar(20), cotatva int, discount decimal(5,2))
		
		-- inserez toate pozitiile din devize (piese + manopera)
		insert into @devize(codDeviz, pozitieDeviz, tert, explicatii, cod, denumire, cantitate, cantitateMinima, um,  pret, valoare, lm, gestiune, cotatva, discount)
			select rtrim(p.cod_deviz), convert(int,p.Pozitie_articol), RTRIM(d.Beneficiar) tert,
					rtrim(p.cod_deviz)+isnull('/'+RTRIM(t.Denumire),'')+'-'+RTRIM(d.Denumire_deviz)+'-'+RTRIM(d.Sesizare_client) explicatii,
					(case when p.Tip_resursa<>'M' then isnull(RTRIM(n.cod),'') else null end) as cod, 
					/* la denumire produs, inserez null EXCLUSIV pt. manopera, pt. ca mai jos cumulez liniile cu manopera in una singura. */
					(case when p.Tip_resursa<>'M' then isnull(RTRIM(n.denumire),'') else null end) as denumire, 
					convert(decimal(12,3),p.Cantitate) as cantitate, convert(decimal(12,3),p.Cantitate) as cantitateMinima, rtrim(n.um) as um, 
					CONVERT(decimal(12,2),p.pret_vanzare * (1+convert(decimal(12,2),p.cota_tva)/100.00)) pret, 
					CONVERT(decimal(12,2),p.Cantitate * p.pret_vanzare * (1+convert(decimal(12,2),p.cota_tva)/100.00)) valoare, 
					rtrim(p.Loc_de_munca) lm, RTRIM(p.Cod_gestiune) as gestiune, p.Cota_TVA cota_tva, convert(decimal(12,2),p.Discount) as discount
				from pozdevauto p
				inner join devauto d on p.Cod_deviz=d.Cod_deviz
				left join nomencl n on n.cod = p.Cod /*left join pt. ca nu va gasi nimic pt. manopere*/
				left join terti t on d.Beneficiar=t.Tert and t.Subunitate=@subunitate
				where p.tip='D' and d.Stare='2' and p.Stare_pozitie='2' AND D.Tip='B'/*BUN DE FACTURAT*/ --and p.tip_resursa='P'
					and (@tert='' or t.Tert=@tert)
					and p.cod_deviz+isnull(t.denumire, '')+d.Sesizare_client+d.Denumire_deviz like @filtru  
				
		-- cumulez manopera pe fiecare deviz.
		insert into @devize(codDeviz, pozitieDeviz, tert, explicatii, cod, denumire, cantitate, cantitateMinima, um, pret, valoare, lm, gestiune, cotatva, discount)
			select codDeviz, null, max(tert), max(explicatii), 
				rtrim(@codManopera), 'Manopera deviz '+codDeviz, 1 cantitate, 1 cantitateMinima, 'BUC' um, 
				sum(valoare*(1.00-discount/100.00)) pret, sum(valoare*(1.00-discount/100.00)) valoare, max(lm), 
				max(gestiune), max(cotatva), 
				0 as discount/* nu trimit discount, ci il aplic direct - pt. cazurile in care doar unele pozitii 
					au discount*/
			from @devize d
			where d.cod is null
			group by codDeviz
		
		delete from @devize 
		where cod is null
		
		set @xmlString=@xmlString+ISNULL(
			(select /*sp top 100 sp*/ tert as tert, 'Dev. '+Explicatii as explicatii, lm as lm,
					codDeviz as coddeviz, pozitieDeviz as pozdeviz, codDeviz as comanda_asis,
					
					-- atribute hardcodate pt. linii PV
					Cod as cod, Denumire as denumire,
					(case when ROUND(Cantitate,0)=CONVERT(decimal(12,3),cantitate) then ltrim(str(cantitate))
						else LTRIM(CONVERT(decimal(12,3),cantitate)) end) as cantitate,
					UM as um, pret as pretcatalog, cotatva as cotatva, discount as discount, 
					gestiune gestiune,
					-- atribute trimise pt. afisare in fereastra de comenzi
					pret as pret, valoare as valoare,
					-- alte atribute
					c.cantitateMinima as cantMinima,/*blocare cantitate pe pozitie*/
					c.cantitate as stocMaxim /*blocare cantitate pe pozitie*/
				from @devize c
				order by c.codDeviz, id 
				for xml raw),'')+CHAR(13)
			
	end
	
	/* 
		apelez procedura specifica la care trimit xmlString si care poate face alte modificari asupra lui..
		parametrul e un string la care se atasaza linii noi.
		atributlele obligatorii sunt 
			- pt. bonuri: @cod, @denumire, @cantitate, @um, @pretcatalog, @cotatva, @discount
			- pt. afisare in macheta: @pret, @valoare, @explicatii
	*/
	if @sesiune='' select @xmlString
	if exists(select * from sysobjects where name='wIaComenziDeFacturatSP1' and type='P')
		exec wIaComenziDeFacturatSP1 @sesiune=@sesiune, @parXML=@parXML, @xmlString=@xmlString output
	
	select CONVERT(xml, @xmlString)
end try
begin catch 
	declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT
	SELECT @ErrorMessage = ERROR_MESSAGE()+'(wIaComenziDeFacturatSP)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch
