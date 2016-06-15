--***

CREATE procedure wScriuNomenclator @sesiune varchar(50), @parXML xml as  
if exists (select 1 from sys.objects where name='wScriuNomenclatorSP' and type='P')  
begin
	exec wScriuNomenclatorSP @sesiune, @parXML
	return
end
if exists (select 1 from sys.objects where name='wScriuNomenclatorSP1' and type='P')  
	exec wScriuNomenclatorSP1 @sesiune, @parXML output

begin try
	Declare @update bit, @cod varchar(20), @grupa varchar(13), @denumire varchar(80), @note varchar(80), @um varchar(3),@cont varchar(40), @cotatva float, @pretvanznom float,
		@codbare varchar(20),@areserii int,@o_areserii int,@Serii int,@pret_stocn float,@observatii varchar(21),@stocmin decimal(12,3),@detalii xml,
		@docDetalii xml, @greutate float,@categorie int,@stocmax decimal(12,3),@tip varchar(1),@um_1 varchar(3),@valuta varchar(3),
		@o_codbare varchar(20), @o_stocmin decimal(12,3), @o_stocmax decimal(12,3), @coeficient_conversie_1 float

	Set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
	Set @grupa = upper(isnull(@parXML.value('(/row/@grupa)[1]','varchar(13)'),''))
	Set @denumire = @parXML.value('(/row/@denumire)[1]','varchar(80)')
	Set @note = isnull(@parXML.value('(/row/@note)[1]','varchar(80)'),'')
	Set @um = upper(isnull(@parXML.value('(/row/@um)[1]','varchar(3)'),'BUC'))
	Set @um_1 = upper(isnull(@parXML.value('(/row/@um_1)[1]','varchar(3)'),''))
	Set @cont = isnull(nullif(@parXML.value('(/row/@cont)[1]','varchar(40)'),''),
		isnull((select detalii.value('(/row/@cont)[1]','varchar(40)') from grupe where grupa=@grupa),'371'))
	Set @cotatva = isnull(@parXML.value('(/row/@cotatva)[1]','float'),24)
	Set @pretvanznom = isnull(@parXML.value('(/row/@pretvanznom)[1]','float'),0)
	Set @pret_stocn = isnull(@parXML.value('(/row/@pret_stocn)[1]','float'),0)
	Set @cod = upper(RTRIM(LTRIM(@parXML.value('(/row/@cod)[1]','varchar(20)'))))
	Set @observatii = isnull(@parXML.value('(/row/@observatii)[1]','varchar(21)'),'')
	Set @codbare = upper(@parXML.value('(/row/@codbare)[1]','varchar(20)'))
	Set @stocmin= isnull(@parXML.value('(/row/@stocmin)[1]','decimal(12,3)'),0)
	Set @stocmax= isnull(@parXML.value('(/row/@stocmax)[1]','decimal(12,3)'),0)
	Set @greutate= isnull(@parXML.value('(/row/@greutate)[1]','float'),0)
	Set @categorie= isnull(@parXML.value('(/row/@categorie)[1]','int'),0)
	set @detalii= @parXML.query('/row/detalii')
	Set @areserii= @parXML.value('(/row/@areserii)[1]','int')
	Set @valuta= isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),'')
	Set @o_stocmin= isnull(@parXML.value('(/row/@o_stocmin)[1]','decimal(12,3)'),0)
	Set @o_stocmax= isnull(@parXML.value('(/row/@o_stocmax)[1]','decimal(12,3)'),0)
	Set @o_areserii= @parXML.value('(/row/@o_areserii)[1]','int')
	Set @o_codbare = @parXML.value('(/row/@o_codbare)[1]','varchar(20)')
	Set @coeficient_conversie_1 = isnull(@parXML.value('(/row/@coeficient_conversie_1)[1]','float'),0)

	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''
	
	if exists (select 1 from sys.objects where name='wCodificareSP' and type='P') and ISNULL(@cod,'')='' 
	begin
		exec wCodificareSP @sesiune, @parXML output
		Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
	end

	set @tip=isnull((select tip_de_nomenclator from grupe where grupa=@grupa),'A')

	if @um not in ('', 'BUC') and not exists (select 1 from um where um.UM=@um)
		raiserror('Unitate de masura invalida!',11,1)
		
	/** Afisare mesaj de eroare in cazul in care se incearca bifarea "codul are serii" si nu este pusa bifa generala "Se lucreaza cu serii"	 **/
	if @Serii=0 and @areserii=1 and isnull(@o_areserii,0)=0
		raiserror('Pentru a se putea bifa "Codul are serii", este nevoie ca setarea "Se lucreaza cu serii" sa fie activa!',11,1)
	
	if @update=1  
	begin  
		update nomencl set Tip = @tip, Grupa=@grupa, Denumire=@denumire, Loc_de_munca=@note, UM=@um, Cont=@cont, UM_1=@um_1, coeficient_conversie_1=@coeficient_conversie_1,
				Cota_TVA=@cotatva, Pret_vanzare=@pretvanznom ,Pret_stoc=convert(decimal(17,5),@pret_stocn), 
				tip_echipament=@observatii,Valuta=@valuta,
				UM_2= case when @Serii=1 and @areserii=1 and @o_areserii=0 then 'Y' else case when @areserii=0 and @o_areserii=1 then '' else UM_2 end end,
				Greutate_specifica=@greutate, Categorie=@categorie
					--> daca codul are serii, se pune 'Y' in campul UM_2 din nomencl 
			where Cod=@cod
		
		if @codbare is not null
		begin
			delete from codbare where Cod_de_bare=@o_codbare
		end
	end  
	else   
	begin    
		declare @cod_par varchar(20)    
		if (isnull(@cod,'')='')  
		begin	
			exec wMaxCod 'cod','nomencl',@cod_par output
			set @cod=@cod_par
		end
		else 
			set @cod_par=@cod    
		insert into nomencl (Cod, Tip, Grupa, Denumire, UM, UM_1, Coeficient_conversie_1, UM_2, Coeficient_conversie_2, Cont, Valuta, Pret_in_valuta, Pret_stoc, Pret_vanzare, Pret_cu_amanuntul, Cota_TVA, 
			Stoc_limita, Stoc, Greutate_specifica, Furnizor, Loc_de_munca, Gestiune, Categorie, Tip_echipament)  
		values (@cod_par, @tip, @grupa, @denumire, @um,@um_1,@coeficient_conversie_1,case when @areserii=1 and @Serii=1 then 'Y' else '' end,
			0,@cont,@valuta,0,convert(decimal(17,5),@pret_stocn),@pretvanznom,0,@cotatva,0,0,@greutate,'',@note,'',@categorie,@observatii)  
	end
	
	set @docDetalii=(select 'nomencl' as tabel, @cod as cod, @detalii  for xml raw)
	exec wScriuDetalii @parXML=@docDetalii
	
	/** Tratare stoc minim si maxim-> tabela stoclim **/
	if ( @stocmin>0 OR @stocmax>0) or (@stocmin<> @o_stocmin OR @stocmax<>@o_stocmax)
	begin
		delete from stoclim where cod=@cod and cod_gestiune=''
			
		insert into stoclim(subunitate,tip_gestiune,cod_gestiune,cod,data,Stoc_min,stoc_max,pret,locatie)
		values('1','','',@cod,getdate(),@stocmin,@stocmax,0,'')

	end

	if isnull(@codbare,'')<>'' 
	begin
		if @codbare='GENERARE'
			exec generareEan @codbare=@codbare output, @sesiune=@sesiune, @parXML=@parXML

		insert into codbare(Cod_de_bare,Cod_produs,UM)
		select @codbare,@cod,1
		where not exists (select 1 from codbare where cod_de_bare=@codbare)
	end

	if @parXML.value('/row[1]/@_butonAdaugare','varchar(50)') = '1'
	begin
		set @parXML = 
			(select top 1 rtrim(@cod) as cod, rtrim(denumire) as denumire from nomencl where cod=@cod for xml raw)
	
		if @parXML is not null
			exec wIaNomenclator @sesiune=@sesiune, @parXML=@parXML
	end
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()+' (wScriuNomenclator)'
	raiserror(@mesaj, 11, 1)	
end catch 
