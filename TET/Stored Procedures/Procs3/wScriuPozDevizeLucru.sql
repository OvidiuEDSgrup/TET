CREATE procedure  [dbo].[wScriuPozDevizeLucru]  @sesiune varchar(50), @parXML XML
as
-- declarare variabile pentru inregistrarile din tabela "pozdevauto"
declare  @tip char(1) , @coddeviz char(20) , @pozitiearticol float , @tipresursa char(1) , @cod char(20) ,
	@cantitate float , @timpnormat float , @tariforar float , @pretdestoc float , @adaos real ,
	@discount real , @pretvanzare float , @contdestoc char(13) , @codcorespondent char(20) ,
	@datalansarii datetime , @oraplanificata char(6) , @numarconsum char(8) ,@datafinalizarii datetime,
	@orafinalizarii char(6) , @codgestiune char(9) , @starepozitie char(1) , @locdemunca char(9) ,
	@marca char(6) , @codintrare char(13) ,@utilizator char(10) ,@dataoperarii datetime ,@oraoperarii char(6) ,
	@utilizatorconsum char(10) , @utilizatorfacturare char(10) , @numaraviz char(8) ,@datafacturarii datetime ,
	@promotie char(13) ,@generatie smallint ,@confirmattelefonic bit ,@explicatii char(100) ,@cotaTVA smallint ,
	@tarif varchar(13),
	
-- declarare variabile pentru tabele antet , "devauto"
	@denumiredeviz char(50),  @oralansarii char(6),
	@datainchiderii datetime , @autovehicul char(20), @KMbord float, @executant char(9), @beneficiar char(13),
	@valoaredeviz float,  @valoarerealizari float, @sesizareclient char(200), @constatareservice char(200),
	@observatii char(200), @stare char(1), @termendeexecutie datetime, @oraexecutie char(6),
	@numardedosar char(8), @factura char(8), 
	
--Altele
	@subtip varchar(2), @update bit

-- setare filtre pt inregistrarile din tabela antet "devauto"	
set @denumiredeviz= rtrim(isnull(@parXML.value('(/row/@denumiredeviz)[1]', 'varchar(10)'), ''))
set @datainchiderii= @parXML.value('(/row/@datainchiderii)[1]','datetime')
set @sesizareclient= rtrim(isnull(@parXML.value('(/row/@sesizareclient)[1]', 'varchar(10)'), ''))
set @constatareservice= rtrim(isnull(@parXML.value('(/row/@constatareservice)[1]', 'varchar(10)'), ''))
set @KMbord= rtrim(isnull(@parXML.value('(/row/@kmbord)[1]', 'float'), ''))
set @numardedosar= rtrim(isnull(@parXML.value('(/row/@numardedosar)[1]', 'varchar(10)'), ''))
set @beneficiar= rtrim(isnull(@parXML.value('(/row/@beneficiar)[1]', 'varchar(50)'), ''))
set @autovehicul= rtrim(isnull(@parXML.value('(/row/@autovehicul)[1]', 'varchar(10)'), ''))

-- setare filtre pt inregistrarile din tabela de pozitii "pozdevauto"
set @tip= rtrim(isnull(@parXML.value('(/row/@tip)[1]', 'varchar(10)'), ''))
set @coddeviz= rtrim(isnull(@parXML.value('(/row/@coddeviz)[1]', 'varchar(10)'),''))
set	@pozitiearticol= rtrim(isnull(@parXML.value('(/row/@pozitiearticol)[1]', 'float'), ''))
set	@timpnormat = rtrim(isnull(@parXML.value('(/row/@timpnormat)[1]', 'float'), ''))
set @tariforar= rtrim(isnull(@parXML.value('(/row/@tariforar)[1]', 'float'), ''))
set	@pretdestoc = rtrim(isnull(@parXML.value('(/row/@pretdestoc)[1]', 'float'), ''))
set	@adaos = rtrim(isnull(@parXML.value('(/row/@adaos)[1]', 'real'), ''))
set	@discount = rtrim(isnull(@parXML.value('(/row/@discount)[1]', 'real'), ''))
set	@contdestoc = rtrim(isnull(@parXML.value('(/row/@contdestoc)[1]', 'varchar(50)'), ''))
set	@codcorespondent= rtrim(isnull(@parXML.value('(/row/@codcorespondent)[1]', 'varchar(50)'), ''))
set	@datalansarii = rtrim(isnull(@parXML.value('(/row/@datalansarii)[1]', 'datetime'), '01/01/1901'))
set	@oraplanificata = rtrim(isnull(@parXML.value('(/row/@oraplanificata)[1]', 'varchar(50)'), ''))
set	@numarconsum = rtrim(isnull(@parXML.value('(/row/@numarconsum)[1]', 'varchar(50)'), ''))
set	@datafinalizarii = rtrim(isnull(@parXML.value('(/row/@datafinalizarii)[1]', 'datetime'), '01/01/1901'))
set	@orafinalizarii = rtrim(isnull(@parXML.value('(/row/@orafinalizarii)[1]', 'varchar(50)'), ''))
--Daca nu este configurata citirea campului de gestiune se va pune din parametrii
set	@codgestiune= rtrim(isnull(@parXML.value('(/row/@codgestiune)[1]', 'varchar(50)'), 
	(select top 1 val_alfanumerica from par where tip_parametru='SA' and parametru='GESTIUNE')))
set	@starepozitie = rtrim(isnull(@parXML.value('(/row/@starepozitie)[1]', 'varchar(50)'), ''))
set	@locdemunca = rtrim(isnull(@parXML.value('(/row/@locdemunca)[1]', 'varchar(50)'), ''))
set	@marca = rtrim(isnull(@parXML.value('(/row/@marca)[1]', 'varchar(50)'), ''))
set	@codintrare = rtrim(isnull(@parXML.value('(/row/@codintrare)[1]', 'varchar(50)'), ''))

exec wIaUtilizator @sesiune, @utilizator OUTPUT

set	@dataoperarii = rtrim(isnull(@parXML.value('(/row/@dataoperarii)[1]', 'datetime'), '01/01/1901'))
set	@oraoperarii = rtrim(isnull(@parXML.value('(/row/@oraoperarii)[1]', 'varchar(50)'), ''))
set	@utilizatorconsum= rtrim(isnull(@parXML.value('(/row/@utilizatorconsum)[1]', 'varchar(50)'), ''))
set	@utilizatorfacturare = rtrim(isnull(@parXML.value('(/row/@utilizatorfacturare)[1]', 'varchar(50)'), ''))
set	@numaraviz = rtrim(isnull(@parXML.value('(/row/@numaraviz)[1]', 'varchar(50)'), ''))
set	@datafacturarii = rtrim(isnull(@parXML.value('(/row/@datafacturarii)[1]', 'datetime'), '01/01/1901'))
set	@promotie = rtrim(isnull(@parXML.value('(/row/@promotie)[1]', 'varchar(50)'), ''))
set	@generatie = rtrim(isnull(@parXML.value('(/row/@generatie)[1]', 'smallint'), ''))
set	@confirmattelefonic = rtrim(isnull(@parXML.value('(/row/@confirmattelefonic)[1]', 'bit'), ''))
set	@explicatii = rtrim(isnull(@parXML.value('(/row/@explicatii)[1]', 'varchar(50)'), ''))
set	@cotaTVA = isnull(@parXML.value('(/row/@cotaTVA)[1]', 'smallint'),-1)

-- campurile ce apar in meniul de adaugare / modificare 
set	@subtip = rtrim(isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'),''))
set	@cantitate= rtrim(isnull(@parXML.value('(/row/row/@cantitate)[1]', 'float'), ''))
set	@pretvanzare = rtrim(isnull(@parXML.value('(/row/row/@pretvanzare)[1]', 'float'), 0))
set	@tarif= rtrim(isnull(@parXML.value('(/row/row/@tarif)[1]', 'float'), 0))
set	@cod = isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), '')
set @tipresursa=substring(@subtip,2,1)

if isnull(@coddeviz, '')=''
begin
   declare @NrDocFisc int, @fXML xml, @tipPentruNr varchar(2)
	set @tipPentruNr='AP'
	set @fXML = '<row/>'
	---- tip =DL neaparat
	set @fXML.modify ('insert attribute tipmacheta {"AP"} into (/row)[1]')
	set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
	set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
	set @fXML.modify ('insert attribute lm {sql:variable("@locdemunca")} into (/row)[1]')
				
	exec wIauNrDocFiscale @fXML, @NrDocFisc output
	
	if ISNULL(@NrDocFisc, 0)<>0
		set @coddeviz=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
end

if @cotaTVA = -1 
   begin 
      set @cotaTVA = null 
      exec luare_date_par @tip='GE', @par='COTATVA', @val_l='',  @val_n=@cotaTVA output, @val_a=''
   end 

--Declarare varaibile pt modificare/ update
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/row/@update)[1]', 'int'), 0)   

--Determinare tip pozitie
--Subtip 'DM' - manopera , Subtip 'DP' - piesa
	if @modificare=0 and @subtip in ('DM', 'DP')  
		begin
			if @coddeviz = '' or @pretvanzare < 0  or @cantitate  <= 0
			begin
				raiserror('Nu sunt permise: valori negative, cod necompletat',11,1)
				return -1
	    	end		    	
			set @oralansarii=convert(varchar(10),getdate(),108)  
			set @stare ='1'
				if not exists (select 1 from devauto where cod_deviz=@coddeviz and denumire_deviz=@denumiredeviz )
				begin
					-- inserare date in tabela antet "devauto"						
					insert into  devauto 
						(Cod_deviz,Denumire_deviz,Data_lansarii ,Ora_lansarii ,Data_inchiderii ,
						Autovehicul, KM_bord, Executant ,Beneficiar ,Valoare_deviz,Valoare_realizari,
						Sesizare_client ,Coonstatare_service,Observatii, Stare ,
						Termen_de_executie , Ora_executie,Numar_de_dosar ,Tip, Factura)
					values 
						(@coddeviz,	@denumiredeviz , @datalansarii, @oralansarii ,@datainchiderii, @autovehicul, 
						 @KMbord, '', @beneficiar, 0,  0 ,  @sesizareclient, @constatareservice,'', '', getdate(),'' , '', '', '')  								                                                     
				end
		begin 
		if @tipresursa='P'
		begin
			if @codgestiune is null
			begin
				raiserror('Violare integritate date (wScriuPozDevizeLucru) Gestiunea necompletata). ',11,1)
				return -1
			end
			if @pretvanzare=0
			   begin
				declare @dXML xml
				set @dXML = '<row/>'
				set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
				set @dXML.modify ('insert attribute tert {sql:variable("@beneficiar")} into (/row)[1]')
				set @dXML.modify ('insert attribute data {sql:variable("@datalansarii")} into (/row)[1]')
				declare @dstr char(10)
				set @dstr=convert(char(10),@datalansarii,101)											
				if @pretvanzare=0 set @pretvanzare=null
				  exec wIaPretDiscount @dXML, @pretvanzare output, @discount output										
			   end
		end		
		select @pozitiearticol=(select max(pozitie_articol) from pozdevauto where cod_deviz=@coddeviz)+1   
		if @pozitiearticol is null  set @pozitiearticol=1
		select @pretvanzare=isnull(@pretvanzare, 0), @discount=isnull(@discount, 0)
		 if isnull(@coddeviz,'')<> '' set  @tip='D' 
		 -- inserare date in tabela de pozitii "pozdevauto" 
		 
		 -- pentru inregistrarile de tip "manopera" se face AC(autocomplete) cu valoare tarifului in campul "pret vanzare", tariful se ia din tabela "catop"
		 set @pretvanzare=(case when @subtip='DM' then (select top 1 tarif from catop where cod=@tarif)
								when @subtip='DP' then @pretvanzare end) 
								
		 if not exists(select 1 from pozdevauto where tip_resursa=@tipresursa and cod_deviz=@coddeviz and cod=@cod and pozitie_articol=@pozitiearticol) 
			insert into pozdevauto 
				( Tip , Cod_deviz ,Pozitie_articol,Tip_resursa ,Cod ,Cantitate,Timp_normat,
				Tarif_orar,Pret_de_stoc,Adaos,Discount,Pret_vanzare ,Cont_de_stoc,Cod_corespondent,Data_lansarii,
				Ora_planificata,Numar_consum, Data_finalizarii,Ora_finalizarii ,Cod_gestiune ,Stare_pozitie,
				Loc_de_munca ,Marca,Cod_intrare,Utilizator,Data_operarii,Ora_operarii,Utilizator_consum,
				Utilizator_facturare,Numar_aviz,Data_facturarii,Promotie,Generatie,Confirmat_telefonic,
				Explicatii,Cota_TVA)
			values
				(@tip, @coddeviz,@pozitiearticol, @tipresursa, @cod,
				@cantitate , @timpnormat, @tariforar, @pretdestoc, @adaos,
				@discount, @pretvanzare, @contdestoc, @codcorespondent,
				@datalansarii, @oraplanificata, @numarconsum ,@datafinalizarii ,
				@orafinalizarii , @codgestiune, @starepozitie, @locdemunca  ,
				@marca , @codintrare ,@utilizator,@dataoperarii,@oraoperarii  ,
				@utilizatorconsum  , @utilizatorfacturare, @numaraviz,@datafacturarii  ,
				@promotie  ,@generatie ,@confirmattelefonic,@explicatii,@cotaTVA)	
			else 
			 raiserror('insert pozdevauto duplicat',16,1)
	    end																																												
	end
	  
-- modificare  date 
    if @modificare=1  and  @subtip in ('DM','DP')
	begin
	 update pozdevauto set pret_vanzare=@pretvanzare, cantitate=@cantitate, cod=@cod 
			where Cod_deviz=@coddeviz 
				and tip=rtrim(isnull(@parXML.value('(/row/linie/@tip)[1]', 'varchar(10)'), ''))
				and Tip_resursa=rtrim(isnull(@parXML.value('(/row/linie/@tipresursa)[1]', 'varchar(10)'), ''))
				and Cod=rtrim(isnull(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'), ''))
				and Pozitie_articol=rtrim(isnull(@parXML.value('(/row/linie/@pozitiearticol)[1]', 'float'), ''))  
	end
declare @docXMLIaPozDevizeLucru xml
set @docXMLIaPozDevizeLucru ='<row coddeviz="'+rtrim(@coddeviz)+'"/>'
exec wIaPozDevizeLucru @sesiune=@sesiune, @parXML=@docXMLIaPozDevizeLucru
