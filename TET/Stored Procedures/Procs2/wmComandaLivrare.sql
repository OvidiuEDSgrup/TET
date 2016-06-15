--***  
/* afisare pozitii comanda deschisa pe tert */
CREATE procedure wmComandaLivrare @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmComandaLivrareSP' and type='P')
begin
	exec wmComandaLivrareSP @sesiune, @parXML 
	return 0
end

	set transaction isolation level READ UNCOMMITTED  
	declare 
		@utilizator varchar(100),@subunitate varchar(9), @tert varchar(30),
		@comanda varchar(20), @explicatii varchar(100), @linietotal varchar(100), @data datetime,@cod varchar(20), 
		@gestiune varchar(20), @discountMinim decimal(12,2), @discountMaxim decimal(12,2), @pasDiscount decimal(12,2),
		@stareBkFacturabil varchar(20), @stare varchar(50), @rasp varchar(max),@discount decimal(12,2),
		@actiune varchar(30) /* stabilesc actiunea in frame: refresh daca se adauga cu cod de bare,  */, @clearSearch bit /*pentru stergere camp de search*/,
		@discountInPozitii bit,@lVanSales int, @numar_comanda varchar(20), @gestPrim varchar(50), @linie_inchide_com_dep xml, @punctlivrare varchar(20),
		@discount_unic bit

begin try
	select	@clearSearch=0
	exec luare_date_par 'AM','DISCUNICP',@discount_unic OUTPUT,0,''
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	-- citire date din par
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'1') end)			
	from par
	where (Tip_parametru='GE' and Parametru='SUBPRO')or (Tip_parametru='UC' and Parametru = 'STBKFACT')

	set @lVanSales=isnull((select val_logica from par where Tip_parametru='AM' and Parametru='VANSALES'),0)
	
	exec wmIaDiscountAgent @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output

	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)'), 
			@gestPrim=@parXML.value('(/row/@gestprim)[1]','varchar(20)'),
			@punctlivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)')
			
	-- comenzile de livrare pot avea tert sau gestiune primitoare. Gestiunea primitoare se trimite din alta procedura momentan.
	if @tert is null and @gestprim is null
	begin
		set @parXML.modify ('insert attribute wmIaTerti.procdetalii {"wmComandaLivrare"} into (/row)[1]')
		exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
		return 0
	end

	if @comanda is null
	begin 
		select top 1 @comanda=idContract
		from (
				select
					c.idContract,jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn
				from Contracte c
				JOIN JurnalContracte jc on jc.idContract=c.idContract 
				where tip='CL' and (ISNULL(@tert,'')='' or tert=@tert ) and (ISNULL(@gestprim,'')='' or gestiune_primitoare=@gestprim ) and 
				(ISNULL(@punctlivrare,'')=''	 or c.punct_livrare=@punctlivrare)
			) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1
		
		/**daca nu am gasit comanda, creez antetul si mai incerc o data **/
		if @comanda is null
		begin
			
			exec wmScriuAntetComanda @sesiune=@sesiune, @parXML=@parXML OUTPUT

			select @comanda= @parXML.value('(/*/@idContract)[1]','int')
				
			if @comanda is null
			begin -- nu prea se ajunge aici...
				raiserror('(wmComandaLivrare)Nu pot crea o comanda noua!',11,1)
				return -1
			end
		end
		
		select @comanda as '@comanda' for xml path('atribute'),root('Mesaje')
	end

	/** Citesc date antet**/
	select top 1 
		@explicatii=cst.explicatii, @tert=cst.tert, @data=cst.data, @stare=cst.stare, @numar_comanda = cst.numar, 
		@discount=ISNULL(cst.detalii.value('(/*/@discount)[1]','float'),0)
		from (
				select
					jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn,
					c.*
				from Contracte c
				JOIN JurnalContracte jc on jc.idContract=c.idContract and tip='CL' and c.idContract=@comanda
			) cst where cst.utilizator=@utilizator and cst.rn=1

	/* 
		Daca afisez comenzi filtrate pe stari, dau back automat daca se intra pe o comanda care are alta stare:
		De ex: daca se intra pe o comanda de facturat si se factureaza, nu il mai las pe ea...
	*/
	if @parXML.value('(/row/@stare)[1]','varchar(20)') is not null 
		and @parXML.value('(/row/@stare)[1]','varchar(20)')<>@stare
	begin
		select 'back(1)' actiune for xml raw, root('Mesaje')
	end

	select 
		@stareBkFacturabil=ISNULL(facturabil,0)
	from StariContracte where tipContract='CL' and stare=@stare

	/* actualizare data comenzii, daca e primul cod adaugat pe comanda, pt. ca sa nu fie data */
	if not exists (select 1 from PozContracte where idContract=@comanda)
		update Contracte set Data=CONVERT(datetime,convert(varchar,getdate(),101),101)
		where idContract=@comanda

	/** formez linie cu total pe comanda **/
	select 
		@linietotal=LTRIM(str(count(pc.cantitate)))+' art: '+rTRIM(convert(char(20),sum(convert(decimal(12,2), Round(pc.Cantitate*pc.Pret*(1-isnull(pc.discount,0)/100), 2)))))+' LEI'
	from PozContracte pc  
	where pc.idContract=@comanda

	declare @areMeniu int -- Variabila folosita pentru a vedea daca are un meniu sau nu	

	/** linie facturare - daca comanda e in stare facturabil**/	
	exec wAreMeniuMobile 'CFactureaza',@utilizator,@areMeniu output
	declare @linie_facturat xml
	/** acces pe linia de facturat doar daca e in starea corecta, valoare>0 si este tert completat(pt comanda cu gestiune primitoare nu permitem facturare) **/
	if (@stareBkFacturabil=1 or @lVanSales=1) and @areMeniu=1 and @linietotal is not null and isnull(@tert,'')<>''
		set @linie_facturat=
			(
			select 
				'<FacturareComanda>' cod, 'Facturare comanda' denumire, @linietotal info,
				'0x0000ff' as culoare, 'refresh' actiune, 'C' as tipdetalii, 'wmFactureazaComanda' procdetalii,'assets/Imagini/Meniu/Bonuri.png' as poza
			for xml raw, type
			)


	if @stare='0' and @linietotal is not null 
	begin
		DECLARE @linie_inchide_com xml
		/** linie inchide comanda - daca e in stare 0 **/
		exec wAreMeniuMobile 'CInchideComanda',@utilizator,@areMeniu output
		if @areMeniu=1
			set @linie_inchide_com =
				(
				select 
					'' as cod,'Inchide comanda' as denumire,@linietotal as info,
					'0x000000' as culoare, 'refresh' as actiune,/* dau refresh pentru ca dupa inchidere comanda, se da back*/
					'C' as tipdetalii, 'wmInchidComanda' procdetalii,'assets/Imagini/Meniu/Realizari.png' as poza
				for xml raw, type
				)

		/** Inchide in depozit */
		exec wAreMeniuMobile 'CInchideComandaDep',@utilizator,@areMeniu output
		if @areMeniu=1
			set @linie_inchide_com_dep =
				(
				select 
					'1' as cod, '@inDepozit' numeatr, 'Inchide in depozit' as denumire,@linietotal as info,
					'0x000000' as culoare, 'refresh' as actiune,/* dau refresh pentru ca dupa inchidere comanda, se da back*/
					'C' as tipdetalii, 'wmInchidComanda' procdetalii,'assets/Imagini/Meniu/Realizari.png' as poza
				for xml raw, type
				)

		/** linie inchide comanda BON- daca e in stare 0**/
		DECLARE @linie_inchide_bon xml
		exec wAreMeniuMobile 'CBon',@utilizator,@areMeniu output
		if @areMeniu=1
			set @linie_inchide_bon=
				(
				select 
					'1' as cod, '@comspeciala' numeatr, 'Inchid ca bon' as denumire,
					@linietotal as info,
					'0x000000' as culoare, 'refresh' as actiune,/* dau refresh pentru ca dupa inchidere comanda, se da back*/
					'C' as tipdetalii, 'wmInchidComanda' procdetalii,
					'assets/Imagini/Meniu/Realizari.png' as poza
					where @linietotal is not null
				for xml raw, type
				)

		DECLARE @linie_tiparest_bon xml	
		/**  linie tipareste bon - daca e in stare 0, se mai verifica si in flex daca utilizatorul are casa de marcat**/
		exec wAreMeniuMobile 'CTipBon',@utilizator,@areMeniu output
		if @areMeniu=1
			set @linie_tiparest_bon=
				(
					select
						/** Bonul (liniile cu produse) */
						(select rtrim(n.Denumire) as denProdus,RTRIM(convert(char(20),(convert(decimal(12,2),pc.Pret)))) as pret,
							rtrim(LTRIM(convert(char(10),(convert(decimal(12,2),pc.cantitate))))) as cantitate, n.um as uMasura,
							(case when pc.discount<>0 then +LTRIM(str(convert(decimal(12,2),pc.discount))) else null end) as discount,
							@discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas
						from PozContracte pc  
						JOIN Contracte c on c.idContract=pc.idContract
						left outer join nomencl n on pc.Cod=n.Cod  
						where c.Tip='CL' and c.idContract=@comanda and c.Tert=@tert						
						for xml raw, type) as bon,
						'@bon' as numeatr, 'Tipareste bon' as denumire, 'assets/Imagini/Meniu/Bonuri.png' as poza,
						@linietotal as info, '0x000000' as culoare, 'tiparesteBon' as _actiune, /* tiparesteBon cheama actiunea de tiparire bon, si face refresh */
						'C' as _tipdetalii, 'wmTiparesteBon' as _procdetalii -- va fi wmInchidComanda
				for XML raw, type
				)
	end

	/** Linie adaugare cod **/
	DECLARE @linie_adauga xml	
	exec wAreMeniuMobile 'CAdaug',@utilizator,@areMeniu output
	if @areMeniu=1
		set @linie_adauga=
		/** linie cod nou: trimit discount sugerat in cod... */
			(
			select 
				'Adauga cod' denumire, '0x0000ff' as culoare,'C' as tipdetalii, (case @discount_unic when '1' then @discount else 0 end) as discount,
				'wmAlegCod' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza, '1' as _toateAtr
			for xml raw, type
			)
	DECLARE @linie_adauga_promo xml	
	exec wAreMeniuMobile 'CAdaugPromo',@utilizator,@areMeniu output
	if @areMeniu=1
		set @linie_adauga_promo=
		/** linie cod nou: trimit discount sugerat in cod... */
			(
			select 
				'Adauga promo' denumire, '0x0000ff' as culoare,'C' as tipdetalii,'wmAlegPromotie' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza, '1' as _toateAtr
			for xml raw, type
			)

	DECLARE @linie_produse xml	
	set @linie_produse=
		 /**linii cu produse **/
		(
		select 
			rtrim(pc.cod) as cod, rtrim(n.Denumire) as denumire,   
			LTRIM(convert(char(10),(convert(decimal(12,2),pc.cantitate))))+' '+n.um+'*' +RTRIM(convert(char(20),(convert(decimal(12,2),pc.Pret))))+' LEI'+  
				(case when pc.discount<>0 then '(-'+LTRIM(str(convert(decimal(12,2),pc.discount)))+'%)' else '' end) as info, 
			convert(decimal(12,3),pc.cantitate) as cantitate, convert(decimal(12,3),pc.pret) as pret, convert(decimal(12,2),pc.discount) as discount,
			'D' as tipdetalii, 'wmScriuPozitieComanda' procdetalii,@discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas,
			dbo.f_wmIaForm((case pc.subtip when 'PR' then 'PROMO' else 'MD' end)) form,
			pc.detalii.value('(/row/@idpromotie)[1]','int') idpromotie, pc.detalii.value('(/row/@cantitatepromotie)[1]','decimal(15,2)') cantitatepromotie
		from PozContracte pc  
		left outer join nomencl n on pc.Cod=n.Cod  
		where pc.idContract=@comanda
		order by pc.idPozContract
		for xml raw, type
		)

	DECLARE @linie_discount xml	
	exec wAreMeniuMobile 'CDiscount',@utilizator,@areMeniu output
	if @areMeniu=1 and @discount_unic=1
		set @linie_discount=
			(select 
				'<DISCOUNT>' as cod, 'Discount: '+convert(varchar,convert(decimal(12,2),@discount))+'%' as denumire, '' as info,'0x0000ff' as culoare, 
				'D' as tipdetalii , 'back(0)' actiune,'assets/Imagini/Meniu/bag1_64.png' as poza , 'wmModificaDiscountGlobal' as procdetalii,
				dbo.f_wmIaForm('DISC') form, @discount discount, '1' as _toateAtr, @comanda comanda
			for xml raw, type
			)

	SELECT
		@linie_facturat,@linie_inchide_com,@linie_inchide_com_dep,@linie_inchide_bon,@linie_tiparest_bon,@linie_adauga,@linie_adauga_promo,@linie_produse,
		@linie_discount
	for XML PATH('Date')

	select @numar_comanda=numar from Contracte where idContract=@comanda
	select 
		'wmComandaLivrare' as detalii,0 as areSearch, 'Comanda:'+isnull(@numar_comanda,'-') as titlu , @actiune actiune, '@cod' numeatr		
	for xml raw,Root('Mesaje')  

end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+'(wmComandaLivrare)'
	raiserror(@eroare,11,1)
end catch
