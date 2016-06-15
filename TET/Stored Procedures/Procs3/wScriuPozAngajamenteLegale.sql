create procedure  [dbo].[wScriuPozAngajamenteLegale] @sesiune varchar(50), @parXML xml  
as
begin
declare	@mesajeroare varchar(300),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE @indbug varchar(20),@indbug_ang_bug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20), 
	        @data_operarii datetime,@ora_operarii varchar(6),@o_data datetime
	
	Declare @update bit,@numar_ordonantare varchar(8),@data_ordonantare datetime,@numar_ang_bug varchar(8),
	        @data_ang_bug datetime,@numar_ang_legal varchar(8),@data_ang_legal datetime,@contract varchar(20),
	        @mod_de_plata varchar(30),@documente_justificative varchar (200),@o_data_OP datetime,
	        @new_numar varchar(8),@data_OP datetime,
	        @o_numar varchar(8),@contract_AC varchar(30),
	        @compartiment varchar(9),@beneficiar varchar(20),@suma float,@new_suma float,@o_new_suma float,
	        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
	        @stare char(10),@o_stare char(10),@nr_cfp float,@nr_pozitie int,@nr_pozitieNC int,@comanda varchar(40),@new_data_OP datetime,
	        @subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml,@new_valuta char(3),@new_data datetime,@new_explicatii varchar(200),
	        @new_observatii varchar(200),@new_curs float,@new_suma_valuta float,
	        @new_documente_justificative varchar(200),@numar_ang_bug_AC varchar(30),@data_angbug_AC datetime
        --citire date din xml
    begin try   
    begin transaction tran1
    select 
         @indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
         @numar_ordonantare= isnull(@parXML.value('(/row/@numar_ordonantare)[1]','varchar(8)'),''),
         @numar_ang_bug_AC= isnull(@parXML.value('(/row/@numar_ang_bug_AC)[1]','varchar(30)'),''),
         @numar_ang_bug= isnull(@parXML.value('(/row/@numar_ang_bug)[1]','varchar(8)'),''),
         @data_ordonantare= @parXML.value('(/row/@data_ordonantare)[1]','datetime'),
         @data_ang_bug= @parXML.value('(/row/@data_ang_bug)[1]','datetime'),
         @numar_ang_legal= isnull(@parXML.value('(/row/@numar_ang_legal)[1]','varchar(8)'),''),
         @data_ang_legal= @parXML.value('(/row/@data_ang_legal)[1]','datetime'),
         @beneficiar= isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(20)'),''),
         @contract=isnull(@parXML.value('(/row/@contract)[1]','varchar(20)'),''),
         @contract_AC=isnull(@parXML.value('(/row/@contract_AC)[1]','varchar(30)'),''),
         @compartiment= isnull(@parXML.value('(/row/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(/row/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(/row/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(/row/@curs)[1]','float'),0),         
         @mod_de_plata=isnull(@parXML.value('(/row/@mod_de_plata)[1]','varchar(30)'),''),
         @documente_justificative=isnull(@parXML.value('(/row/@documente_justificative)[1]','varchar(200)'),''),
         @observatii= isnull(@parXML.value('(/row/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(/row/@explicatii)[1]','varchar(200)'),''),
         @stare= isnull(@parXML.value('(/row/@stare)[1]','char(10)'),''),
         
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
         @nr_pozitie = isnull(@parXML.value('(/row/row/@nr_pozitie)[1]','int'),0),
         @data_OP = @parXML.value('(/row/row/@data_OP)[1]','datetime'),
         
		 @new_numar= isnull(@parXML.value('(/row/row/@numar)[1]','varchar(8)'),''),
         @new_data= @parXML.value('(/row/row/@data)[1]','datetime'), 
         @new_data_OP= @parXML.value('(/row/row/@data_OP)[1]','datetime'),   
         @new_suma=isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
         @new_valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','char(3)'),''),
         @new_curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
         @new_explicatii=isnull( @parXML.value('(/row/row/@explicatii)[1]','varchar(200)'),''),         
         @new_observatii= isnull(@parXML.value('(/row/row/@observatii)[1]','varchar(200)'),''),
         
         @o_stare= isnull(@parXML.value('(/row/@stare)[1]','char(10)'),''),
         @o_numar= isnull(@parXML.value('(/row/row/@o_numar)[1]','varchar(8)'),''),
         @o_new_suma=isnull(@parXML.value('(/row/row/@o_suma)[1]','float'),0),
         @o_data_OP = @parXML.value('(/row/row/@o_data_OP)[1]','datetime')
         
     	if  @subtip='AO'
     		begin
     			set @numar_ang_bug=(select substring(@numar_ang_bug_AC,1,CHARINDEX('|',@numar_ang_bug_AC,1)-1))
				set @data_angbug_AC=(select substring(@numar_ang_bug_AC,CHARINDEX('|',@numar_ang_bug_AC,1)+1,LEN(@numar_ang_bug_AC)))
			end
		exec wValidareAngajamenteLegale  @parXML     

	--*************************Start adaugare/modificare ordine de plata pe ordonantari **************************
	if @subtip='OP'
	   if @update=1  --daca se modifica un op existent
		 begin			
			set @new_suma_valuta=(case when @new_curs<>0 and @new_valuta<>'' then @new_suma/@new_curs else 0 end)
			
			---verificare suma disponibila pe ordonantare 
			declare @suma_disponibila3 float
			set @suma_disponibila3=@o_new_suma+@suma-isnull((select sum(suma) from pozordonantari where numar_ordonantare=@numar_ordonantare
																									and data_ordonantare=@data_ordonantare),0)
			if @suma_disponibila3<@new_suma --daca suma disponibila pe ordonantare< suma de pe op=>eroare
				begin
					set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@new_suma))+
									') depaseste suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila3))+
									') pe aceasta ordonantare!'
					raiserror(@mesajeroare, 11, 1)
				end				
				
			else
				begin
					--update pe pe nota contabila corespunzatoare op-ului
					update pozncon set numar=@new_numar,data=convert(datetime, convert(char(10), @data_OP, 101), 101), suma=@new_suma,
						valuta=@new_valuta,curs=@new_curs,suma_valuta=@new_suma_valuta,explicatii=@new_observatii,
						utilizator=@utilizator,data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
						ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
					where comanda=space(20)+@indbug and data=@o_data_OP and numar=@o_numar and cont_creditor='8067'
					
					--update pe tabela de pozitii ordonantari unde este tinut op-ul
					update pozordonantari set numar_op=@new_numar ,data_OP=convert(datetime, convert(char(10), @data_OP, 101), 101),
						suma=@new_suma,valuta=@new_valuta,curs=@new_curs,suma_valuta=@new_suma_valuta,
						explicatii=@new_observatii,utilizator=@utilizator,data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
						ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
					where numar_ordonantare=@numar_ordonantare and data_ordonantare=@data_ordonantare 
						and numar_OP=@o_numar and data_op=@o_data_OP
				end
		 end
		 else--daca se adauga op		
			begin
				if @new_data_OP<@data_ordonantare
					begin
						set @mesajeroare='Data OP trebuie sa fie o data ulterioara datei ordonantarii!!'
						raiserror(@mesajeroare,11,1)
					end   
					
				--verificare suma disponibila pe ordonantare
				declare @suma_disponibila2 float
				set @suma_disponibila2=@suma-isnull((select sum(suma) from pozordonantari where numar_ordonantare=@numar_ordonantare
																							and data_ordonantare=@data_ordonantare),0)
				if @suma_disponibila2<@new_suma--daca suma disponibila ese mai mica decat suma de pe op=>eroare 
					begin
						set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@new_suma))+
										') depaseste suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila2))+
										') pe aceasta ordonantare!'
						raiserror(@mesajeroare, 11, 1)
					end
				else
					if not exists (select numar_cfp from registrucfp where numar=@numar_ordonantare and tip='O')
						begin
							set @mesajeroare='Aceasta ordonantare nu are viza CFP!!'
							raiserror(@mesajeroare, 11, 1)
						end
					else 
						set @mesajeroare=''
		
				if @mesajeroare=''                    
					begin                      
						--alocare numar pozitie nota contabila
						exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitieNC output, ''
						set @nr_pozitieNC=@nr_pozitieNC+1
						exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitieNC, null--setare ultim numar pozitie note contabile utilizat 
						
						set @comanda='                    '+ltrim(rtrim(@indbug)) --formare comanda(comanda(20 caractere)+indicator bugetar(20 caractere))
						set @new_suma_valuta=(case when @new_curs<>0 and @new_valuta<>'' then @new_suma/@new_curs else 0 end)   
	     
						--inserare nota contabila corespunzatoare op-ului
						insert into pozncon (subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,curs,suma_valuta,explicatii,utilizator,
							data_operarii, ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal)
						select '1','AO',@new_numar,convert(datetime, convert(char(10), @new_data_OP, 101), 101),'','8067',@new_suma,@new_valuta,@new_curs,@new_suma_valuta,@new_observatii,@utilizator,
							convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),          
							@nr_pozitieNC,@compartiment,@comanda,'',''
	                 
						--identificare numarului de pozitie urmator pt op, in cadrul oronantarii 
						set @nr_pozitie=isnull((select top 1 numar_pozitie from pozordonantari 
						where indicator=@indbug and numar_ordonantare=@numar_ordonantare and data_ordonantare=@data_ordonantare
						order by numar_pozitie desc),0)+1
	      
						--inserare op in tabela pozitii ordonantari
						insert into pozordonantari (indicator,numar_ordonantare,data_ordonantare,numar_pozitie,numar_op,data_op,suma,valuta,curs,suma_valuta,
							explicatii,utilizator,data_operarii,ora_operarii)
						select @indbug,@numar_ordonantare,@data_ordonantare,@nr_pozitie, @new_numar,convert(datetime, convert(char(10), getdate(), 101), 101),
							@new_suma,@new_valuta,@new_curs,@new_suma_valuta,
							@new_observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),
							RTrim(replace(convert(char(8), getdate(), 108), ':', ''))                             
					 end
			end
	--*****************************Stop adaugare/modificare ordine de plata pe ordonantari **************************

	---***********************************Start adaugare ordonantare ***************************************************
	if  @subtip='AO'
		begin
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
								set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
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
				
			declare @compartiment_ang_bug varchar(9),@beneficiar_ang_bug varchar(20),@suma_ang_bug float,@valuta_ang_bug varchar(3),
				@curs_ang_bug float,@suma_valuta_ang_bug float,@data_ang_bug1 datetime,@observatii_ang_bug varchar(30),
				@suma_disponibila float, @suma_disponibila_total float
			
			--verificare suma disponibila pe angajament bugetar
			set @suma_ang_bug=isnull((select suma from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC),0)
			set @compartiment_ang_bug=(select loc_de_munca from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
			set @indbug_ang_bug=(select rtrim(ltrim(indicator)) from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
			set @beneficiar_ang_bug=(select beneficiar from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
			
			set @suma_disponibila=@suma_ang_bug-isnull((select sum(suma) from ordonantari where numar_ang_bug=@numar_ang_bug and data_ang_bug=@data_angbug_AC),0)
			set @suma_disponibila_total=isnull((select sum(suma) from angbug where Loc_de_munca=@compartiment_ang_bug and indicator=@indbug_ang_bug),0)-
										isnull((select sum(suma) from ordonantari where rtrim(Compartiment) like rtrim(@compartiment_ang_bug)+'%' and indicator=@indbug_ang_bug),0)
 
 --select @suma_ang_bug as angbug_s,@suma_disponibila as disp,isnull((select sum(suma) from ordonantari where numar_ang_bug=@numar_ang_bug and data_ang_bug=@data_angbug_AC),0) as [suma ordonantata]
 			if @suma_disponibila<@suma--suma disponibila este mai mica decat suma ordonantarii=>eroare
				begin
					set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@suma))+
									') depaseste suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila))+
									') pe acest angajament bugetar!'
					raiserror(@mesajeroare, 11, 1)
				end
			else--suma disponibila este mai mare sau egala cu suma ordonantarii
				begin
					if @suma_disponibila_total<@suma--suma disponibila pe loc de munca si indicator< decat suma ordonantarii=>eroare
						begin
							set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@suma))+
											') depaseste suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila_total))+
											') pe acest indicator si loc de munca!'
							raiserror(@mesajeroare, 11, 1)
						end
				
					declare @UltNrOrdonantare char(8) 
					
					--alocare numar ordonantare
					exec luare_date_par 'GE', 'ULTNRALEG', '', @UltNrOrdonantare output, 0
					set @UltNrOrdonantare=@UltNrOrdonantare+1 
					while exists (select 1 from ordonantari where Numar_ordonantare=@UltNrOrdonantare and year(Data_ordonantare)=YEAR(@data_ordonantare))
						set @UltNrOrdonantare=@UltNrOrdonantare+1 
					exec setare_par 'GE','ULTNRALEG','Ultimul nr. angajament legal',null,@UltNrOrdonantare,null--setare ultim numar folosit
					set @numar_ordonantare=@UltNrOrdonantare 
 
					---preluare date de pe angajamentul bugetar intordus
					set @data_ang_bug1=(select data from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
					set @observatii_ang_bug=(select observatii from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
					set @valuta_ang_bug=(select @valuta from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
					set @curs_ang_bug=(select curs from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)
					set @suma_valuta_ang_bug=(select suma_valuta from angbug where  numar=@numar_ang_bug and data=@data_angbug_AC)

					if rtrim(@compartiment) not like rtrim(@compartiment_ang_bug)+'%'
						raiserror('Compartimentul nu a fost introdus corect!!',11,1)
					
					--insert in tabela de ordonantari
					insert into ordonantari(indicator,numar_ordonantare,data_ordonantare,numar_ang_bug,data_ang_bug,numar_ang_legal,data_ang_legal,
                        beneficiar,contract,compartiment,suma,valuta,curs,suma_valuta,mod_de_plata,documente_justificative,
                        observatii,utilizator,data_operarii,ora_operarii)
					select @indbug_ang_bug,@numar_ordonantare,convert(datetime, convert(char(10), @data_ordonantare, 101), 101),
						@numar_ang_bug,@data_angbug_AC,@numar_ordonantare,convert(datetime, convert(char(10), @data_ordonantare, 101), 101),
						@beneficiar_ang_bug,@contract,@compartiment,@suma,@valuta_ang_bug,@curs_ang_bug,@suma_valuta_ang_bug,
						@mod_de_plata,@documente_justificative,@observatii_ang_bug,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),
						RTrim(replace(convert(char(8), getdate(), 108), ':', ''))            
 
				end
			set @indbug=@indbug_ang_bug	
		end
commit transaction tran1
---***********************************Stop adaugare ordonantare ***************************************************
	--apelare procedura pt refresh in pozitii ordonantari
	declare @docXMLIaPozOrd xml 
	set @docXMLIaPozOrd = '<row numar_ordonantare="' + rtrim(@numar_ordonantare)+
	                      '" indbug="'+rtrim(@indbug)+
	                   -- '" data_ang_bug="' + convert(char(10), @data_ang_bug, 101) +
                          '" numar_ang_bug="'+rtrim(@numar_ang_bug)+
                          '" data_ordonantare="' + convert(char(10), @data_ordonantare, 101) +
                      '"/>'
	exec wIaPozAngajamenteLegale @sesiune=@sesiune, @parXML=@docXMLIaPozOrd	
end try	
begin catch
	rollback transaction tran1
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
end
--select * from pozordonantari
