--***

create procedure [dbo].[wmScriuPozitieComanda] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmScriuPozitieComandaSP' and type='P')
begin
	exec wmScriuPozitieComandaSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare 
	@utilizator varchar(100),@subunitate varchar(9), @tert varchar(20),@data datetime, @idPunctLivrare varchar(30), 
	@stareBkFacturabil varchar(20), @stare varchar(50), @gestiune varchar(20), @comanda varchar(20), @cod varchar(20),
	@cantitate decimal(12,3),@pret decimal(12,3),@discount decimal(12,3),@primaCon bit, @eroare varchar(4000),
	@input XML, @lVanSales int, @stoc float, @vanzareFaraStoc bit, @gestPrim varchar(50), @discount_unic bit, @idPromotie int,
	@detalii_pozitie xml, @detalii_existente xml, @sql varchar(max)

begin try 
	set @data=convert(char(10),GETDATE(),101)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	exec luare_date_par 'AM','DISCUNICP',@discount_unic OUTPUT,0,''

	/** Citire date din par */
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'1') end),
			@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else isnull(@stareBkFacturabil,'1') end)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='AM' and Parametru='DISCPOZ')
		or (Tip_parametru='UC' and Parametru = 'STBKFACT')

	select @subunitate=isnull(@subunitate,'1')
	set @lVanSales=isnull((select val_logica from par where Tip_parametru='AM' and Parametru='VANSALES'),0)
	
	exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc output, null, null
	
	select	@comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)'),
			@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@idPunctLivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)'),
			@cod=@parXML.value('(/row/@cod)[1]','varchar(20)'),
			@cantitate=@parXML.value('(/row/@cantitate)[1]','decimal(12,3)'),
			@pret=@parXML.value('(/row/@pret)[1]','decimal(12,3)'),
			@discount=@parXML.value('(/row/@discount)[1]','decimal(12,3)'),
			@idPromotie=@parXML.value('(/row/@idpromotie)[1]','int')
	
	-- Tratam detalii
	declare @atribute table (id int identity, atribut varchar(100), valoare varchar(500), val_existenta varchar(500))
	insert into @atribute(atribut,valoare)
	select replace(convert(varchar(100),x.v.query('local-name(.)')),'detalii_',''), rtrim(x.v.value('.','varchar(500)')) from @parXML.nodes('//@*') x(v)
	where convert(varchar(100),x.v.query('local-name(.)')) like 'detalii_%'
	select @detalii_pozitie = convert(xml,'<row ' + stuff((select ' ' + atribut + '="' + valoare + '"' from @atribute for xml path(''),type).value('.','varchar(max)'), 1, 1, '') + ' />')

	IF @idPromotie IS NULL
		begin
		select top 1 @data=cst.data, @idPunctLivrare=cst.Punct_livrare, @gestiune=cst.Gestiune, @stare=cst.Stare, @gestPrim=cst.gestiune_primitoare
			from (
				select
					c.*,jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn
				from Contracte c
				JOIN JurnalContracte jc on jc.idContract=c.idContract and tip='CL' and  c.idContract=@comanda
			) cst where cst.utilizator=@utilizator and cst.rn=1
	
		declare @explicatii varchar(80)
		set @explicatii=ISNULL((select top 1 rtrim(denumire) from terti where tert=@tert),'')
	
		/** daca se vinde in regim van-sales, validam stocul pt. ca aceste comenzi se factureaza pe loc din asismobile **/
		if @vanzareFaraStoc=0 and @lVanSales=1 and (select n.Tip from nomencl n where n.Cod=@cod)<>'S' 
			and isnull(@gestPrim,'')=''
		begin
			set @stoc=ISNULL((select sum(stoc) from stocuri s where s.Subunitate=@subunitate and s.Cod=@cod and s.Cod_gestiune=@gestiune),0)
		
			if @cantitate>@stoc
			begin
				set @eroare='Cantitatea introdusa depaseste stocul disponibil ('+ convert(varchar, convert(decimal(12,3),@stoc)) +').'
				raiserror(@eroare, 11,1)
			end
		end

		if not exists ( select 1 from PozContracte pc where pc.idcontract=@comanda and pc.Cod=@cod )
		begin 
			begin try -- folosesc try catch pt. ca sa ma asigur ca se schimba starea inapoi in 1
				set @eroare = null
				set @input=
					(
						select 
							c.idContract, c.tip,c.numar,c.data,c.tert,c.gestiune,c.loc_de_munca as lm,c.explicatii,c.punct_livrare,1 fara_luare_date,
							c.gestiune_primitoare,c.detalii detalii,
							(
							select 
								@cod as cod,convert(char(10),convert(decimal(12,3),isnull(@cantitate,1))) as cantitate,@comanda idContract,
								isnull(@discount,0) as discount,@pret as pret, @detalii_pozitie as detalii
							for xml raw,type
							)
						from Contracte c where c.idContract=@comanda
						for xml RAW, type
					)
				exec wScriuPozContracte @sesiune=@sesiune,@parXML=@input
			end try 
			begin catch
				set @eroare=ERROR_MESSAGE()
			end catch	
		
			if @eroare is not null
				raiserror(@eroare, 16, 1) 
		end
		else
		begin -- modificare cod existent pe comanda
			if @cantitate=0 -- cantitate=0 => sterg cod de pe comanda
				delete from pozContracte where idContract=@comanda and  cod=@cod
			
			/*
			-- Updatez detaliile existente
			if exists(select 1 from @atribute)
			begin
				-- Iau detaliile existente
				select @detalii_existente = detalii from PozContracte where idContract=@comanda and  cod=@cod

				-- Updatez atributele care exista cu noile valori
				update @atribute 
				set val_existenta=rtrim(x.v.value('.','varchar(500)'))
				from @detalii_existente.nodes('//@*') x(v) 
				where atribut=convert(varchar(100),x.v.query('local-name(.)'))

				-- Inserez  atributele care nu exista
				insert into @atribute(atribut,val_existenta)
				select convert(varchar(100),x.v.query('local-name(.)')), rtrim(x.v.value('.','varchar(500)')) from @detalii_existente.nodes('//@*') x(v)
				where not exists(select 1 from @atribute where atribut=convert(varchar(100),x.v.query('local-name(.)')))

				-- Formez XML detalii
				select @detalii_pozitie = convert(xml,'<row ' + stuff((select ' ' + atribut + '="' + coalesce(valoare,val_existenta) + '"' from @atribute for xml path(''),type).value('.','varchar(max)'), 1, 1, '') + ' />')
			end
			*/

			update PozContracte 
				set Cantitate=(case when @stare<>'0' then cantitate /* doar in stare=0 se poate umbla la coloana cantitate */
									when @cantitate is null then Cantitate 
									else @cantitate end),
				pret=(case when @pret is null then pret else @pret end), 
				discount=(case when @discount is null then discount else @discount end),
				detalii=@detalii_pozitie
			where idContract=@comanda and  cod=@cod
		
		end
	end
	else
	begin
		declare 
			@contract xml
		delete PozContracte where idContract=@comanda and detalii.value('(/*/@idpromotie)[1]','int')=@idpromotie
		select @cantitate=@parXML.value('(/row/@cantitatepromotie)[1]','decimal(12,3)')

		set @contract=
		(
			select
				c.idContract, c.tip,c.numar,c.data,c.tert,c.gestiune,c.loc_de_munca as lm,c.explicatii,c.punct_livrare,
				1 fara_luare_date, c.gestiune_primitoare,c.detalii detalii, 'comanda' _document, @idPromotie idpromotie, @cantitate cantitatepromotie,
				( select (select @idPromotie idpromotie, @cantitate cantitatepromotie for xml raw, type) detalii for xml raw, type)				
			from Contracte c where idContract=@comanda
			for xml raw, type
		)

		exec wOPTrateazaPromotie @sesiune=@sesiune, @parXML=@contract
	end
	IF @discount_unic =1 and @discount is not null
		-- setez acelasi discount la toate produsele de pe comanda - discount-ul se da pe comanda
		update PozContracte set discount= @discount
		where idContract=@comanda and discount<>@discount
	/* 
		mitz: pentru backcount ar trebui sa trimitem in un atribut specificand de cate ori sa dea back.
		fiecare procedura implicata in deschidere view care apoi trebuie sa fie inchis, 
		va citi acel atribut, si il va incrementa(se poate trimite in mesaj, in nodul <atribute>)
	*/
	if isnull(@parXML.value('(/row/@faradetalii)[1]','int'),0)=0
		select 'back(1)' as actiune 
		for xml raw,Root('Mesaje')

end try
begin catch
	set @eroare=ERROR_MESSAGE()+'(wmScriuPozitieComanda)'
	raiserror(@eroare,11,1)
end catch
