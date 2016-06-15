
CREATE procedure wmComandaAsistent @sesiune varchar(50), @parXML xml  
as
if exists(select * from sysobjects where name='wmComandaAsistentSP' and type='P')
begin
	exec wmComandaAsistentSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30),
		@comanda varchar(20), @explicatii varchar(100), @linietotal varchar(100), @data datetime,@cod varchar(20), 
		@gestiune varchar(20), @discountMinim decimal(12,2), @discountMaxim decimal(12,2), @pasDiscount decimal(12,2),
		@stareBkFacturabil varchar(20), @stare varchar(50), @rasp varchar(max), @discountSugerat decimal(12,2),
		@actiune varchar(30) /* stabilesc actiunea in frame: refresh daca se adauga cu cod de bare,  */, @clearSearch bit /*pentru stergere camp de search*/,
		@discountInPozitii bit,@lVanSales int, @numar_comanda varchar(20), @gestPrim varchar(50), @linie_inchide_com_dep xml,
		@comandaNoua bit,@tert_gen varchar(20)

begin try
	select	@clearSearch=0

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	-- citire date din par
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'1') end),
			@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else isnull(@stareBkFacturabil,'1') end),
			@discountInPozitii=(case when Parametru='DISCPOZ' then Val_logica else isnull(@discountInPozitii,0) end)
	from par
	where (Tip_parametru='GE' and Parametru='SUBPRO') or (Tip_parametru='AM' and Parametru='DISCPOZ')
		or (Tip_parametru='UC' and Parametru = 'STBKFACT')

	set @lVanSales=isnull((select val_logica from par where Tip_parametru='AM' and Parametru='VANSALES'),0)
	
	exec wmIaDiscountAgent @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output

	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)'), 
			@gestPrim=@parXML.value('(/row/@gestprim)[1]','varchar(20)'),
			@comandaNoua=ISNULL(@parXML.value('(/*/@comandaNoua)[1]','bit'),0)
	
	SELECT top 1 @tert_gen=Val_alfanumerica
		from par where Tip_parametru='UC' and Parametru='TERTGEN'
		
	if @comandaNoua=1 and isnull(@tert,'')=''
	begin
		select 0 as '@comandaNoua' for xml path('atribute'),root('Mesaje')     		
		set @comanda = ''
		set @tert=''
	end
		
	-- comenzile de livrare pot avea tert sau gestiune primitoare. Gestiunea primitoare se trimite din alta procedura momentan.
	if isnull(@tert,'')='' and @gestprim is null
	begin
		set @parXML.modify ('insert attribute wmIaTerti.procdetalii {"wmComandaAsistent"} into (/row)[1]')
		exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
		return 0
	end		


	if isnull(@comanda,'')=''
	begin 
		select top 1 @comanda=idContract
		from (
				select
					c.idContract,jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn
				from Contracte c
				JOIN JurnalContracte jc on jc.idContract=c.idContract 
				where tip='CL' and (@tert is null or tert=@tert ) and (@gestprim is null or gestiune_primitoare=@gestprim )
			) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1

		if @comandaNoua=1
			set @comanda = ''
		/**daca nu am gasit comanda, creez antetul si mai incerc o data **/
		if isnull(@comanda,'')=''
		begin
			
			exec wmScriuAntetComanda @sesiune=@sesiune, @parXML=@parXML OUTPUT

			select @comanda= @parXML.value('(/*/@idContract)[1]','int')
				
			if isnull(@comanda,'')=''
			begin -- nu prea se ajunge aici...
				raiserror('Nu pot crea o comanda noua!',11,1)
				return -1
			end
		end
		
		select @comanda as '@comanda' for xml path('atribute'),root('Mesaje')
	end
	
	/** Citesc date antet**/
	select top 1 @explicatii=cst.explicatii, @tert=cst.tert, @data=cst.data, @stare=cst.stare, @numar_comanda = cst.numar
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

	/* actualizare data comenzii, daca e primul cod adaugat pe comanda, pt. ca sa nu fie data */
	if not exists (select 1 from PozContracte where idContract=@comanda)
		update Contracte set Data=CONVERT(datetime,convert(varchar,getdate(),101),101)
		where idContract=@comanda

	/** formez linie cu total pe comanda **/
	select 
		@linietotal=LTRIM(str(count(pc.cantitate)))+' art: '+rTRIM(convert(char(20),sum(convert(decimal(12,2), Round(pc.Cantitate*pc.Pret*(1-pc.discount/100), 2)))))+' LEI',
		@discountSugerat=(case when @discountInPozitii=1 then min(pc.Discount) else @discountSugerat end)
	from PozContracte pc  
	where pc.idContract=@comanda

	/**  iau discount acordat tertului, daca nu sunt alte pozitii cu discount.*/
	select 
		@discountSugerat=isnull(@discountSugerat, convert(decimal(12,2),t.Disccount_acordat)) 
	from terti t where t.Tert=@tert

	declare @areMeniu int -- Variabila folosita pentru a vedea daca are un meniu sau nu

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
					'0x000000' as culoare, 'refresh' as actiune,
					 'wmInchidComandaAsistent' procdetalii,'assets/Imagini/Meniu/Realizari.png' as poza,
					 (case when @tert=@tert_gen THEN dbo.f_wmIaForm('CE') end) form,
					 (case when @tert=@tert_gen THEN 'D' else 'C' end) tipdetalii
				for xml raw, type
				)
		select
			1 as _neimportant
		where @tert=@tert_gen
		for xml raw, root('Mesaje')
	end

	/** Linie adaugare cod **/
	DECLARE @linie_adauga xml	
	exec wAreMeniuMobile 'CAdaug',@utilizator,@areMeniu output
	if @areMeniu=1
		set @linie_adauga=
		/** linie cod nou: trimit discount sugerat in cod... */
			(
			select 
				convert(varchar(30), @discountSugerat) cod, '@discount' numeatr, 'Adauga cod' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 
				'wmAlegCod' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza,  1 toateAtr
			for xml raw, type
			)

	/** Linie anulare comanda **/
	DECLARE @linie_anuleaza xml
	exec wAreMeniuMobile 'CAnulez',@utilizator,@areMeniu output	
	if @areMeniu=1
		set @linie_anuleaza =
			(
			select 
				@comanda cod, 'Anuleaza comanda' denumire, '0xAA0000' as culoare,'C' as tipdetalii, 
				'wmAnuleazaComanda' procdetalii,'server://assets/Imagini/Meniu/no.png' as poza,  1 toateAtr
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
			'D' as tipdetalii, 'wmScriuPozitieComanda' procdetalii,@discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas
		from PozContracte pc  
		left outer join nomencl n on pc.Cod=n.Cod  
		where pc.idContract=@comanda
		order by pc.idPozContract
		for xml raw, type
		)

	SELECT
		@linie_inchide_com,@linie_adauga,@linie_anuleaza,@linie_produse
	for XML PATH('Date')

	select @numar_comanda=numar from Contracte where idContract=@comanda
	select 
		'wmComandaAsistent' as detalii,0 as areSearch, 'Comanda:'+isnull(@numar_comanda,'-') as titlu , @actiune actiune, '@cod' numeatr,'D' as tipdetalii,
		dbo.f_wmIaForm('MD') form
	for xml raw,Root('Mesaje')  

end try
begin catch
	declare @eroare varchar(max)
	set @eroare=ERROR_MESSAGE()+' (wmComandaAsistent)'
	raiserror(@eroare,11,1)
end catch
