create PROCEDURE [dbo].[wUAScriuAbonati]
 @sesiune [varchar](50),
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @codabonat varchar(30),@o_codabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30),
	@update int,@mesajeroare varchar(500),@utilizator varchar(10), @userASiS varchar(20),@observatii varchar(50),
	@denumireabonat varchar(70),@grupa varchar(30),@centru  varchar(30),@zona varchar(30),@judet varchar(30),
	@localitate varchar(8),@strada varchar(30),@nr varchar(30),@bl varchar(30),@sc varchar(30),@ap varchar(30),
	@et varchar(30),@lm varchar(30),@nrtemp int,@categorie int,@telefon char(30),@tert varchar(30),@pltva int,
	@inmatriculare varchar(30),@cod_fiscal varchar(30),@codbanca varchar(30),@contbanca varchar(30),@codpostal varchar(30)
   
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  

begin try        
    select
        @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
        @codabonat=rtrim(ltrim(isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(30)'), ''))),
        @o_codabonat=rtrim(ltrim(isnull(@parXML.value('(/row/@o_codabonat)[1]', 'varchar(30)'), ''))),
        @denumireabonat=rtrim(ltrim(isnull(@parXML.value('(/row/@denumireabonat)[1]', 'varchar(70)'), ''))),
        @grupa=rtrim(ltrim(isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(30)'), ''))),
        @centru=rtrim(ltrim(isnull(@parXML.value('(/row/@centru)[1]', 'varchar(30)'), ''))),
        @zona=rtrim(ltrim(isnull(@parXML.value('(/row/@zona)[1]', 'varchar(30)'), ''))),
        @judet=rtrim(ltrim(isnull(@parXML.value('(/row/@judet)[1]', 'varchar(30)'), ''))),
        @localitate=rtrim(ltrim(isnull(@parXML.value('(/row/@localitate)[1]', 'varchar(8)'), ''))),
        @strada=rtrim(ltrim(isnull(@parXML.value('(/row/@strada)[1]', 'varchar(30)'), ''))),
        @nr=rtrim(ltrim(isnull(@parXML.value('(/row/@nr)[1]', 'varchar(30)'), ''))),
        @bl=rtrim(ltrim(isnull(@parXML.value('(/row/@bl)[1]', 'varchar(30)'), ''))),
        @sc=rtrim(ltrim(isnull(@parXML.value('(/row/@sc)[1]', 'varchar(30)'), ''))),
        @et=rtrim(ltrim(isnull(@parXML.value('(/row/@et)[1]', 'varchar(30)'), ''))),
        @ap=rtrim(ltrim(isnull(@parXML.value('(/row/@ap)[1]', 'varchar(30)'), ''))),
        @lm=rtrim(ltrim(isnull(@parXML.value('(/row/@lm)[1]', 'varchar(30)'), ''))),
        @categorie=isnull(@parXML.value('(/row/@categorie)[1]', 'int'), ''),
		@telefon=ltrim(rtrim(isnull(@parXML.value('(/row/@telefon)[1]', 'varchar(30)'), ''))),
		@inmatriculare=ltrim(rtrim(isnull(@parXML.value('(/row/@inmatriculare)[1]', 'varchar(30)'), ''))),
		@cod_fiscal=ltrim(rtrim(isnull(@parXML.value('(/row/@cod_fiscal)[1]', 'varchar(30)'), ''))),
		@codbanca=ltrim(rtrim(isnull(@parXML.value('(/row/@codbanca)[1]', 'varchar(30)'), ''))),
		@contbanca=ltrim(rtrim(isnull(@parXML.value('(/row/@contbanca)[1]', 'varchar(30)'), ''))),
		@codpostal=ltrim(rtrim(isnull(@parXML.value('(/row/@codpostal)[1]', 'varchar(30)'), ''))),
		@tert=ltrim(rtrim(isnull(@parXML.value('(/row/@tert)[1]', 'varchar(30)'), ''))),
		@observatii=ltrim(rtrim(isnull(@parXML.value('(/row/@observatii)[1]', 'varchar(50)'), ''))),
		@pltva=ltrim(rtrim(isnull(@parXML.value('(/row/@pltva)[1]', 'varchar(30)'), '')))
    
    if exists (select 1 from sys.objects where name='wUAScriuInfoAbonatiSP' and type='P')
		exec wUAScriuInfoAbonatiSP @sesiune, @parXML
	else   
	begin
	
	---------
	set @Utilizator=dbo.fIauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	
	if (@lista_lm=1 and @lm='') or (@lista_lm=1 and not exists (select cod from lm where Cod=@lm))
		begin     
			set @mesajeroare='Intorduceti un loc de munca valid!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	
	if @zona='' or @centru='' or @grupa=''
		begin     
			set @mesajeroare='Trebuie completate zona, centrul si grupa !'  
			raiserror(@mesajeroare,11,1)  
		end
	if @update=0
	begin	
		if @codabonat=''  
		begin  
			set @nrtemp=0  
			exec wIauNrDocUA 'UA',@utilizator,'' ,@nrtemp output  
			if @nrtemp>99999999 or @nrtemp=0
			begin     
				set @mesajeroare='Eroare la obtinerea nr. de document!'  
				raiserror(@mesajeroare,11,1)  
			end
			else set @codabonat=(CAST(@nrtemp as CHAR(8)))
		end
		
		--exec wUAValidareAbonati  @parXML   
		if @codabonat in (select abonat from abonati)
		begin     
			set @mesajeroare='Codul de abonat '+@codabonat+' exista deja !'  
			raiserror(@mesajeroare,11,1)  
		end
		else insert into abonati(abonat,denumire,Inmatriculare,Strada,Numar,Bloc,Scara,Etaj,Ap,Cod_postal,Loc_de_munca,
							Zona,Centru,Telefon,Banca,Cont_in_Banca,Judet,Localitate,Sold_maxim,Cod_fiscal,Discount,
							Cont_specific,Tert_din_CG,Grupa,Este_tert,Platitor_tva,Categorie,Observatii,Utilizator,
							Data_operarii,Val1,Val2,Alfa1,Alfa2,Data1)
			select @codabonat,@denumireabonat,@inmatriculare,@strada,@nr,@bl,@sc,@et,@ap,
				@codpostal,@lm,@zona,@centru,@telefon,@codbanca,@contbanca,@judet,@localitate,0,@cod_fiscal,
				'','',@tert,@grupa,0,@pltva,@categorie,@observatii,@userASiS,GETDATE(),0,0,'','',''
	end
	else 
	begin
		if @codabonat<>@o_codabonat 
		begin     
				set @mesajeroare='Nu se poate modifica codul abonatului'
				raiserror(@mesajeroare,11,1)  
		end
			
		update abonati set denumire=@denumireabonat,Strada=@strada,Numar=@nr,Bloc=@bl,Scara=@sc,Etaj=@et,Ap=@ap,
			Loc_de_munca=@lm,Zona=@zona,Centru=@centru,Judet=@judet,Localitate=@localitate,Tert_din_CG=@tert,Grupa=@grupa,
			categorie=@categorie,Telefon=@telefon,Inmatriculare=@inmatriculare,Cod_fiscal=@cod_fiscal,
			Banca=@codbanca,Cont_in_Banca=@contbanca,Cod_postal=@codpostal,Platitor_tva=@pltva,observatii=@observatii
			where abonat=@codabonat
	end
	end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch
