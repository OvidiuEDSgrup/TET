create procedure  [dbo].[wOPModificareAngBug] @sesiune varchar(50), @parXML xml  
as
begin
declare	@mesajeroare varchar(300),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
if @utilizator is null
	return -1

DECLARE @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@n_indbug varchar (20), 
        @data_operarii datetime,@ora_operarii varchar(6),@n_data datetime,@suma_valuta float,@n_suma float,
		@numar varchar(8),@data datetime,@compartiment varchar(9),@beneficiar varchar(20),@suma float,
        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),
        @subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml
   
begin try
    --citire date din xml    
    select 
         @indbug= isnull(@parXML.value('(/parametri/@indbug)[1]','varchar(20)'),''),
         @subtip= isnull(@parXML.value('(/parametri/@subtip)[1]','varchar(2)'),''),
         @numar= isnull(@parXML.value('(/parametri/@numar)[1]','varchar(8)'),''),
         @data= isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01-01-1901'),
         @compartiment= isnull(@parXML.value('(/parametri/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(/parametri/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(/parametri/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(/parametri/@curs)[1]','float'),0),
         @beneficiar= isnull(@parXML.value('(/parametri/@beneficiar)[1]','varchar(20)'),''),
         @observatii= isnull(@parXML.value('(/parametri/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(/parametri/@explicatii)[1]','varchar(200)'),''),
         
         @n_suma=isnull(@parXML.value('(/parametri/@n_suma)[1]','float'),0),
         @n_indbug= isnull(@parXML.value('(/parametri/@n_indbug)[1]','varchar(20)'),''),
         @n_data= isnull(@parXML.value('(/parametri/@n_data)[1]','datetime'),'01-01-1901')
         
	if  isnull(@n_indbug,'')=''
		begin
			set @mesajeroare='Introduceti indicatorul bugetar pentru acest angajament!!'
			raiserror(@mesajeroare,11,1)
		end 
	   
	if not exists (select indbug from indbug where indbug=@n_indbug )
		begin
			set @mesajeroare='Indicatorul introdus nu exista in baza de date!!'
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
		
	if exists (select 1 from registrucfp r where r.indicator=@indbug and r.numar=@numar and r.data=@data) 
		begin
			set @mesajeroare='Nu se pot modifica datele unui angajament bugetar care a primit viza CFP!!'
			raiserror(@mesajeroare,11,1)				
		end 	
	
 declare @suma_disponibila float
 set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @n_suma/@curs else 0 end)
 set @suma_disponibila=
        isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=@n_indbug 
                                                                          and p.tip='AO' 
                                                                          and substring(p.numar,1,7)in ('BA_TRIM')
                                                                          and datepart(quarter,p.data)<=datepart(quarter,@n_data) 
                                                                          and year(p.data)=year(@n_data))),0)+
        isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=@n_indbug 
                                                                                             and p.tip='AO' 
                                                                                             and substring(p.numar,1,7)in ('RB_TRIM')
                                                                                             and p.data<=@n_data
                                                                                             and year(p.data)=year(@n_data))),0)-                                                                       
        isnull(convert(decimal(12,3), (select sum(suma)from angbug where indicator=@n_indbug 
                                                                     and stare>'0'
                                                                     and stare<>'4'
                                                                     and datepart(quarter,data)<=datepart(quarter,@n_data) 
                                                                     and year(data)=year(@n_data))),0)
 --if @indbug=@indbug 
   -- set @suma_disponibila1=@suma_disponibila1+@o_suma
 if  @suma_disponibila<@n_suma
 	begin
 	set @mesajeroare='Suma introdusa ('+convert(varchar,convert(decimal(12,3),@n_suma))+
	                 ') este mai mare decat suma disponibila ('+convert(varchar,(convert(decimal(12,3),@suma_disponibila)))+
	                 ') pe acest indicator bugetar!!'
		raiserror(@mesajeroare, 11, 1)
	end	
	else
	  begin
        update angbug set 
				indicator=(case when isnull(@n_indbug,'')<>'' then @n_indbug else indicator end),
				loc_de_munca=(case when isnull(@compartiment,'')<>'' then @compartiment else loc_de_munca end),
				beneficiar=(case when isnull(@beneficiar,'')<>'' then @beneficiar else beneficiar end),
				data=@n_data,
                suma=(case when isnull(@n_suma,0)<>0 then @n_suma else suma end),
                valuta=(case when isnull(@valuta,'')<>'' then @valuta else valuta end),
                curs=(case when isnull(@curs,0)<>0 then @curs else curs end),
                suma_valuta=(case when isnull(@suma_valuta,0)<>0 then @suma_valuta else suma_valuta end),
                explicatii=@explicatii,
                observatii=@observatii,
                utilizator=@utilizator,
                data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
                ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,data_angajament='1901-01-01 00:00:00.000'
         where numar = @numar and indicator=@indbug and data=@data
        
      end
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
	
end 
--select
