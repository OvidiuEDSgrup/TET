create procedure  [dbo].[wOPModificareAngLeg] @sesiune varchar(50), @parXML xml  
as

declare	@mesajeroare varchar(300),@utilizator char(10), @sub char(9),@tip char(2),
		@update bit,@numar_ordonantare varchar(8),@data_ordonantare datetime,@numar_ang_bug varchar(8),
        @data_ang_bug datetime,@numar_ang_legal varchar(8),@data_ang_legal datetime,@contract varchar(20),
        @mod_de_plata varchar(30),@documente_justificative varchar (200),@contract_AC varchar(30),
        @n_numar_ang_bug varchar(8),@n_data_ordonantare datetime,@numar_ang_bug_AC varchar(30),@data_angbug_AC datetime,
        @o_numar varchar(8),  @compartiment varchar(9),@beneficiar varchar(20),@suma float,@n_suma float,
        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
        @stare char(10),@comanda varchar(40),@subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml,
        @indbug varchar(20),@indbug_ang_bug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30)	   
   
begin try
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
    --citire date din xml    
    select 
         @indbug= isnull(@parXML.value('(/parametri/@indbug)[1]','varchar(20)'),''),
         @numar_ordonantare= isnull(@parXML.value('(/parametri/@numar_ordonantare)[1]','varchar(8)'),''),
         @numar_ang_bug= isnull(@parXML.value('(/parametri/@numar_ang_bug)[1]','varchar(8)'),''),
         @numar_ang_bug_AC= isnull(@parXML.value('(/parametri/@numar_ang_bug_AC)[1]','varchar(30)'),''),
         @data_ordonantare= @parXML.value('(/parametri/@data_ordonantare)[1]','datetime'),
         @data_ang_bug= @parXML.value('(/parametri/@data_ang_bug)[1]','datetime'),
         @numar_ang_legal= isnull(@parXML.value('(/parametri/@numar_ang_legal)[1]','varchar(8)'),''),
         @data_ang_legal= @parXML.value('(/parametri/@data_ang_legal)[1]','datetime'),
         @beneficiar= isnull(@parXML.value('(/parametri/@beneficiar)[1]','varchar(20)'),''),
         @contract=isnull(@parXML.value('(/parametri/@contract)[1]','varchar(20)'),''),
         @contract_AC=isnull(@parXML.value('(/parametri/@contract_AC)[1]','varchar(30)'),''),
         @compartiment= isnull(@parXML.value('(/parametri/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(/parametri/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(/parametri/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(/parametri/@curs)[1]','float'),0),         
         @mod_de_plata=isnull(@parXML.value('(/parametri/@mod_de_plata)[1]','varchar(30)'),''),
         @documente_justificative=isnull(@parXML.value('(/parametri/@documente_justificative)[1]','varchar(200)'),''),
         @observatii= isnull(@parXML.value('(/parametri/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(/parametri/@explicatii)[1]','varchar(200)'),''),
         @stare= isnull(@parXML.value('(/parametri/@stare)[1]','char(10)'),''),
         
         @n_suma=isnull(@parXML.value('(/parametri/@n_suma)[1]','float'),0),
         @n_numar_ang_bug= isnull(@parXML.value('(/parametri/@n_numar_ang_bug)[1]','varchar(20)'),''),
         @n_data_ordonantare= isnull(@parXML.value('(/parametri/@n_data_ordonantare)[1]','datetime'),'01-01-1901')
         
	--despartim informatia primita din AC-ul de ang bug in numarul angbug si data lui
	
	set @n_numar_ang_bug=(select substring(@numar_ang_bug_AC,1,CHARINDEX('|',@numar_ang_bug_AC,1)-1))
	set @data_angbug_AC=(select substring(@numar_ang_bug_AC,CHARINDEX('|',@numar_ang_bug_AC,1)+1,LEN(@numar_ang_bug_AC)))
	
	if  isnull(@n_numar_ang_bug,'')=''
		begin
			set @mesajeroare='Introduceti un angajament bugetar valid!!'
			raiserror(@mesajeroare,11,1)
		end 
	   
	if not exists (select Numar from angbug where Numar=@n_numar_ang_bug )
		begin
			set @mesajeroare='Angajamentul bugetar introdus nu exista in baza de date!!'
			raiserror(@mesajeroare,11,1)
		end  
		
	if isnull(@compartiment,'')<>'' and not exists (select cod from lm where cod=@compartiment )
		begin
			set @mesajeroare='Compartimentul introdus nu exista in baza de date!!'
			raiserror(@mesajeroare,11,1)
		end  
	
	if isnull(@beneficiar,'')<>'' and not exists (select cod from lm where cod=@beneficiar )
		begin
			set @mesajeroare='Beneficiarul introdus nu exista in baza de date!!'
			raiserror(@mesajeroare,11,1)
		end   	 		

	if @n_suma=0
		begin
			set @mesajeroare='Suma nu poate fi 0!!'
			raiserror(@mesajeroare,11,1)
		end   
	
	if exists (select 1 from registrucfp r where r.indicator=@indbug 
                                         and r.numar=@numar_ordonantare
                                         and r.data=@data_ordonantare 
                                         and r.tip='O')
       begin
       set @mesajeroare='Nu se pot modifica datele unei ordonantari care are viza CFP!!'
       raiserror(@mesajeroare,11,1)
       end	
		
 --*****************************Start modificare date ordonantare ***************************************************
    declare @tip_AC varchar(1),@tert varchar(20)
			if ISNULL(@contract_AC,'')<>''--daca se foloseste Ac-ul de contracte+terti
				begin
					set @tip_AC=(select substring(@contract_AC,1,CHARINDEX('|',@contract_AC,1)-1))
					set @contract= null
						if @tip_AC='c'--daca se primeste un contract atunci se seteaza contractul
							begin
								set @contract=(select substring(@contract_AC,CHARINDEX('|',@contract_AC,1)+1,LEN(@contract_AC)))
							end
						else--daca primim un tert, generam un contrac pt el, si apoi setam contractul
							begin
								set @tert=(select substring(@contract_AC,CHARINDEX('|',@contract_AC,1)+1,LEN(@contract_AC)))
								
								--generare numar pt noul contract
								declare @NrDocFisc int, @fXML xml
								
								set @fXML = '<row/>'
								set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')
								set @fXML.modify ('insert attribute tip {"FA"} into (/row)[1]')
								set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
								set @fXML.modify ('insert attribute lm {sql:variable("@compartiment")} into (/row)[1]')
								
								exec wIauNrDocFiscale @fXML, @NrDocFisc output
								
								if ISNULL(@NrDocFisc, 0)<>0
									set @contract=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
								if isnull(@contract, '')=''
								begin
									declare @ParUltNr char(9), @UltNr int
									set @ParUltNr='NRCNT' + 'FA'
									exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0
									set @UltNr=@UltNr+1
									
									while @UltNr=0 or exists (select 1 from con where subunitate='1' and tip='FA' and contract=rtrim(ltrim(convert(char(9), @UltNr))))
										set @UltNr=@UltNr+1
									set @contract=rtrim(ltrim(convert(char(9), @UltNr)))
									exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null
								end
								
									--inserare antetului de contract
								insert con 
									(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Stare, Loc_de_munca, Gestiune, Termen, Scadenta, 
									Discount, Valuta, Curs, Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA, 
									Contract_coresp, Mod_penalizare, Procent_penalizare, Procent_avans, Avans, 
									Nr_rate, Val_reziduala, Sold_initial, Cod_dobanda, Dobanda, 
									Incasat, Responsabil, Responsabil_tert, Explicatii, Data_rezilierii)
								select '1', 'FA', @contract, @tert, '', @data_ordonantare, '0', @compartiment, '', '', '', 
									0, @Valuta, @Curs, '', '', '', 0, 0, 
									'', '', '', 0, 0, 
									0, '', '', '', 0, 
									0, '', '', '', '1/1/1901'							
															
							end
				end
    --daca s-a schimbat angajamentul bugetar atunci se iau datele corespunzatoare noului angbug introdus  
	if @n_numar_ang_bug<>@numar_ang_bug
		begin
			set @beneficiar=(select beneficiar from angbug where  numar=@n_numar_ang_bug and data=@data_angbug_AC)
			set @compartiment=(select loc_de_munca from angbug where  numar=@n_numar_ang_bug and data=@data_angbug_AC)
		end                                           
   
	--identificare suma disponibila pe angajamentul bugetar introdus   
	declare @suma_ang_bug float,@suma_disponibila float
	set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end) 
	set @suma_ang_bug=isnull((select suma from angbug where  numar=@n_numar_ang_bug and data=@data_angbug_AC),0)
	set @suma_disponibila=@suma_ang_bug-isnull((select sum(suma) from ordonantari where numar_ang_bug=@n_numar_ang_bug and data_ang_bug=@data_angbug_AC),0)
	set @indbug_ang_bug=(select rtrim(ltrim(indicator)) from angbug where  numar=@n_numar_ang_bug and data=@data_angbug_AC)

	if @n_numar_ang_bug=@numar_ang_bug
		set @suma_disponibila=@suma_disponibila+@suma
	
	if @suma_disponibila<@n_suma--daca suma introdusa este mai mare decat suma disponibila=>eroare
		begin
			set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@n_suma))+
							') depaseste suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila))+
							') pe acest angajament bugetar!'
			raiserror(@mesajeroare, 11, 1)
		end
	else
		begin		
			--modificare date ordonantare cu noile date introduse pe machta de modificare date ordonantare
			update ordonantari set 
				numar_ang_bug=case when isnull(@n_numar_ang_bug,'')<>'' then @n_numar_ang_bug else numar_ang_bug end,
				data_ang_bug=@data_angbug_AC,
				data_ordonantare=@n_data_ordonantare,
				data_ang_legal=@n_data_ordonantare,
				beneficiar=case when isnull(@beneficiar,'')<>''then @beneficiar else beneficiar end,
				indicator= @indbug_ang_bug,
				contract=case when isnull(@contract,'')<>''then @contract else contract end,
				compartiment=case when isnull(@compartiment,'')<>''then @compartiment else compartiment end,
				suma=case when isnull(@n_suma,0)<>0 then @n_suma else suma end,
				valuta=case when isnull(@valuta,'')<>''then @valuta else valuta end,
				curs=case when isnull(@curs,0)<>0 then @curs else curs end,
				mod_de_plata=case when isnull(@mod_de_plata,'')<>''then @mod_de_plata else mod_de_plata end,
				documente_justificative=case when isnull(@documente_justificative,'')<>''then @documente_justificative else documente_justificative end,
				observatii=case when isnull(@observatii,'')<>''then @observatii else observatii end,
				utilizator=@utilizator,data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
				ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		        
			where numar_ordonantare=@numar_ordonantare and data_ordonantare=@data_ordonantare
				and numar_ang_bug=@numar_ang_bug --and data_ang_bug=@new_data_ang_bug
		end
---***********************************Stop modificare date ordonantare ***************************************************
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
	

--select * from ordonantari
