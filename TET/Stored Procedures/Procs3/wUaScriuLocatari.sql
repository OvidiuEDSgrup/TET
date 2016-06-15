/****** Object:  StoredProcedure [dbo].[wUaScriuLocatari]    Script Date: 01/05/2011 22:59:01 ******/
--***
create procedure [dbo].[wUaScriuLocatari]  @sesiune varchar(50), @parXML xml
as
begin
declare @update bit,@id_contract int, @utilizator varchar(13),@abonat varchar(13),@nume varchar(50),@locatar varchar(13),
        @cant_contractata float,@banca varchar(2),@cont_banca varchar(4),@pers_contact varchar(30),@strada varchar(8),
        @adr_nr varchar(5),@adr_bl varchar(5),@adr_sc varchar(5),@adr_ap varchar(5),@cod_postal varchar(10),@email varchar(30),
        @tel_fix varchar(10),@tel_fax varchar(10),@tel_mobil varchar(10),@adrFact bit,@tip_confirmare varchar(1),@tip_locatar varchar(1),
        @centru varchar(20),@validat bit,@mesaj varchar(200),@CNP varchar(20),@nr_autorizatie varchar(20),@explicatii varchar(30),
        @nr_act varchar(20),@nr_containere float
        
        
        
--select * from locatari
--sp_help locatari
begin try	
	select
		@locatar = ltrim(rtrim(isnull(@parXML.value('(/row/row/@locatar)[1]','varchar(13)'),''))),
		@abonat = ltrim(rtrim(isnull(@parXML.value('(/row/@codabonat)[1]','varchar(13)'),''))),
		@id_contract = isnull(@parXML.value('(/row/row/@id_contract)[1]','int'),0),
		@nume = ltrim(rtrim(isnull(@parXML.value('(/row/row/@nume)[1]','varchar(50)'),''))),
		@cant_contractata=isnull(@parXML.value('(/row/row/@cant_contractata)[1]','float'),0),
		@nr_containere=isnull(@parXML.value('(/row/row/@nr_containere)[1]','float'),0),
		@banca = ltrim(rtrim(isnull(@parXML.value('(/row/row/@banca)[1]','varchar(20)'),''))),
		@nr_autorizatie = ltrim(rtrim(isnull(@parXML.value('(/row/row/@nr_autorizatie)[1]','varchar(20)'),''))),
		@nr_act = ltrim(rtrim(isnull(@parXML.value('(/row/row/@nr_act)[1]','varchar(20)'),''))),
		@cont_banca = ltrim(rtrim(isnull(@parXML.value('(/row/row/@cont_banca)[1]','varchar(40)'),''))),
		@pers_contact = ltrim(rtrim(isnull(@parXML.value('(/row/row/@pers_contact)[1]','varchar(30)'),''))),	
		@explicatii = ltrim(rtrim(isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(30)'),''))),
		@CNP = ltrim(rtrim(isnull(@parXML.value('(/row/row/@CNP)[1]','varchar(20)'),''))),
		@strada = ltrim(rtrim(isnull(@parXML.value('(/row/row/@strada)[1]','varchar(8)'),''))),
		@adr_nr = ltrim(rtrim(isnull(@parXML.value('(/row/row/@adr_nr)[1]','varchar(5)'),''))),
		@adr_bl = ltrim(rtrim(isnull(@parXML.value('(/row/row/@adr_bl)[1]','varchar(5)'),''))),
		@adr_sc = ltrim(rtrim(isnull(@parXML.value('(/row/row/@adr_sc)[1]','varchar(5)'),''))),
		@adr_ap = ltrim(rtrim(isnull(@parXML.value('(/row/row/@adr_ap)[1]','varchar(5)'),''))),
		@cod_postal = ltrim(rtrim(isnull(@parXML.value('(/row/row/@cod_postal)[1]','varchar(10)'),''))),
		@email = ltrim(rtrim(isnull(@parXML.value('(/row/row/@email)[1]','varchar(30)'),''))),
		@tel_fix = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tel_fix)[1]','varchar(10)'),''))),
		@tel_mobil = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tel_mobil)[1]','varchar(10)'),''))),
		@tel_fax = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tel_fax)[1]','varchar(10)'),''))),
		@adrFact = isnull(@parXML.value('(/row/row/@adresa_facturare)[1]','bit'),0),
		@tip_confirmare = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tip_confirmare)[1]','varchar(1)'),''))),
		@tip_locatar = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tip_locatar)[1]','varchar(1)'),''))),
		@centru = ltrim(rtrim(isnull(@parXML.value('(/row/row/@tip_centru)[1]','varchar(20)'),''))),
		@validat = isnull(@parXML.value('(/row/row/@validat)[1]','bit'),0),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		
		
		@utilizator=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	
	
	if @update=0
	begin
	  select @Abonat,@Locatar,@Nume,@Cant_contractata,@banca,@Cont_banca,@Pers_contact,@Strada,@Adr_nr,@Adr_bl,@Adr_sc,@Adr_ap,@Cod_postal,
           @Email,@Tel_fix,@Tel_mobil,@Tel_fax, '',0,'',0,0,0,0,@id_contract,@AdrFact,@Tip_confirmare,@Tip_locatar,0,@Centru,'',
           '',@Validat,'','','',''
	
	  INSERT INTO [Locatari]([Abonat] ,[Locatar],[Nume],[Cant_contractata],[Banca] ,[Cont_banca]  ,[Pers_contact] ,[Strada]
           ,[Adr_nr] ,[Adr_bl],[Adr_sc] ,[Adr_ap] ,[Cod_postal] ,[Email] ,[Tel_fix] ,[Tel_mobil],[Tel_fax],[Nr_autorizatie],[Suprafata]
           ,[Tip],[Norma_apa],[Canal],[Meteo],[TaxaD] ,[Id_contract],[AdrFact] ,[Tip_confirmare],[Tip_locatar],[Nr_containere],[Centru]
           ,[Nr_act] ,[CNP],[Validat],[Explicatii],[ObActivitate] ,[ServiciuImplicit] ,[TipContainer])
     VALUES
           (@Abonat,@Locatar,@Nume,@Cant_contractata,@banca,@Cont_banca,@Pers_contact,@Strada,@Adr_nr,@Adr_bl,@Adr_sc,@Adr_ap,@Cod_postal,
           @Email,@Tel_fix,@Tel_mobil,@Tel_fax, @nr_autorizatie,0,'',0,0,0,0,@id_contract,@AdrFact,@Tip_confirmare,@Tip_locatar,@nr_containere,@Centru,@nr_act,
           @CNP,@Validat,@explicatii,'','','')	  
	
	 end		
	
	if @update=1
	begin
	  update Locatari set Nume=@nume,Cant_contractata=@cant_contractata,Banca=@banca,Cont_banca=@cont_banca,Pers_contact=@pers_contact,
						  Strada=@strada,Adr_nr=@adr_nr,Adr_bl=@adr_bl,Adr_sc=@adr_sc,Adr_ap=@adr_ap,Cod_postal=@cod_postal,
						  Email=@email,Tel_fax=@tel_fax,Tel_fix=@tel_fix,Tel_mobil=@tel_mobil,Id_contract=@id_contract,AdrFact=@adrFact,
						  Tip_confirmare=@tip_confirmare,Tip_locatar=@tip_locatar,Centru=@centru,Validat=@validat,CNP=@CNP,Nr_autorizatie=@nr_autorizatie,
						  Explicatii=@explicatii,Nr_act=@nr_act,Nr_containere=@nr_containere
	  where Abonat=@abonat and Locatar=@locatar
	end	        
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
end
