create procedure [dbo].[wOPVizaAngajamenteLegale] @sesiune varchar(50), @parXML xml  
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
        @mod_de_plata varchar(30),--@documente_justificative varchar (200),@new_contract varchar(20),@o_data_OP datetime,
        --@o_new_numar_ang_bug varchar(8),@new_data_ordonantare datetime,
        @new_data_CFP datetime,
        --@new_numar_ang_bug varchar(8),@new_mod_de_plata varchar(30),@new_numar varchar(8),
        @data_OP datetime,
        --@o_numar varchar(8),@new_numar_ang_legal varchar(8), @new_numar_ordonantare varchar(8),@o_data_ordonantare datetime,
        @compartiment varchar(9),@beneficiar varchar(20),@suma float,@new_suma float,@o_new_suma float,
        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
        @stare char(10),--@o_stare char(10),
        @nr_cfp float,@nr_pozitie int,@nr_pozitieNC int,@comanda varchar(40),--@new_data_OP datetime,
        @subtip varchar(2),--@docXMLIaPozAngajamenteBugetare xml,@new_valuta char(3),@new_data datetime,@new_compartiment varchar(9),
        --@new_beneficiar varchar(20),@new_explicatii varchar(200),
        --@new_curs float,@new_suma_valuta float,
        --@new_documente_justificative varchar(200),
        @new_observatii varchar(200)
        --citire date din xml

begin try    
    select 
         @indbug= isnull(@parXML.value('(parametri/@indbug)[1]','varchar(20)'),''),
         @numar_ordonantare= isnull(@parXML.value('(parametri/@numar_ordonantare)[1]','varchar(8)'),''),
         @numar_ang_bug= isnull(@parXML.value('(parametri/@numar_ang_bug)[1]','varchar(8)'),''),
         @data_ordonantare= @parXML.value('(parametri/@data_ordonantare)[1]','datetime'),
         @data_ang_bug= @parXML.value('(parametri/@data_ang_bug)[1]','datetime'),
         @numar_ang_legal= isnull(@parXML.value('(parametri/@numar_ang_legal)[1]','varchar(8)'),''),
         @data_ang_legal= @parXML.value('(parametri/@data_ang_legal)[1]','datetime'),
         @beneficiar= isnull(@parXML.value('(parametri/@beneficiar)[1]','varchar(20)'),''),
         @contract=isnull(@parXML.value('(parametri/@contract)[1]','varchar(20)'),''),
         @compartiment= isnull(@parXML.value('(parametri/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(parametri/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(parametri/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(parametri/@curs)[1]','float'),0),         
         @mod_de_plata=isnull(@parXML.value('(parametri/@mod_de_plata)[1]','varchar(30)'),''),
         @observatii= isnull(@parXML.value('(parametri/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(parametri/@explicatii)[1]','varchar(200)'),''),
         @stare= isnull(@parXML.value('(parametri/@stare)[1]','char(10)'),''),
         
         @update = isnull(@parXML.value('(parametri/@update)[1]','bit'),0),
         @subtip= isnull(@parXML.value('(parametri/@subtip)[1]','varchar(2)'),''),
         @nr_pozitie = isnull(@parXML.value('(parametri/@nr_pozitie)[1]','int'),0),
         @data_OP = @parXML.value('(parametri/@data_OP)[1]','datetime'),
         
         @new_data_CFP= isnull(@parXML.value('(parametri/@data_CFP)[1]','datetime'),'01-01-1901'),     
         @new_observatii= isnull(@parXML.value('(parametri/@observatii)[1]','varchar(200)'),'')
    --*****************Start adaugare viza cfp pentru ordonantare ************************

     if @new_data_CFP<@data_ordonantare and (@new_data_CFP<>'01-01-1901') 
		begin
			set @mesajeroare='Data CFP trebuie sa fie o data ulterioara datei ordonantarii!!'
			raiserror(@mesajeroare,11,1)
		end 
		
	if exists(select 1 from registrucfp where Numar=@numar_ordonantare and data=@data_ordonantare and tip='O')
		raiserror('Aceasta ordonantare are deja alocata viza cfp!!',11,1)	
     
     exec luare_date_par 'GE', 'ULTNROPB', 0, @nr_cfp output, ''
	 set @nr_cfp=@nr_cfp+1
	 exec setare_par 'GE', 'ULTNROPB', null, null, @nr_cfp, null 
	 
     set @nr_pozitie=isnull((select top 1 numar_pozitie from registrucfp 
	              where indicator=@indbug and numar=@numar_ordonantare and data=@data_ordonantare and tip='O'
	              order by numar_pozitie desc),0)+1
	      
	 insert into registrucfp (tip,indicator,numar,data,numar_pozitie,numar_cfp,data_cfp,observatii,utilizator,data_operarii,ora_operarii)
	             select 'O',@indbug,@numar_ordonantare,convert(datetime, convert(char(10), @data_ordonantare, 101), 101),@nr_pozitie,@nr_cfp,convert(datetime, convert(char(10), @new_data_CFP, 101), 101),
	             @new_observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
    
     --Adaugare linii corespunzatoare angajamentului legal in pozncon 
     exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitieNC output, ''
	 set @nr_pozitieNC=@nr_pozitieNC+1
	 exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitieNC, null 
	 set @comanda=space(20)+ltrim(rtrim(@indbug)) 
	 set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end)   
     
     insert into pozncon (subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,curs,suma_valuta,explicatii,utilizator,data_operarii,
                          ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal)
                 select '1','AO',@numar_ang_legal,convert(datetime, convert(char(10), @data_ordonantare, 101), 101),'','8066',@suma,@valuta,@curs,@suma_valuta,'Angajare legala '+@numar_ang_legal,@utilizator,
                 convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),          
                 @nr_pozitieNC,@compartiment,@comanda,'',''
     
     
     exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitieNC output, ''
	 set @nr_pozitieNC=@nr_pozitieNC+1
	 exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitieNC, null 
	  
     insert into pozncon (subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,curs,suma_valuta,explicatii,utilizator,data_operarii,
                          ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal)
                 select '1','AO',@numar_ang_legal,convert(datetime, convert(char(10), @data_ordonantare, 101), 101),'8067','',@suma,@valuta,@curs,@suma_valuta,'Angajare legala '+@numar_ang_legal,@utilizator,
                 convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),          
                 @nr_pozitieNC,@compartiment,@comanda,'',''
     
end try
	
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
end
