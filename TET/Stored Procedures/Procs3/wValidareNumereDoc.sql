--***
/****** Object:  StoredProcedure [dbo].[wValidareNumere]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  wValidareNumereDoc @tip varchar(2),@numar varchar(20),@data datetime,@tert varchar(13),@update bit
WITH EXECUTE AS CALLER
AS
begin
	declare @NRUNIC int,@VNRUNIC int,@mesajeroare varchar(200)
	exec luare_date_par 'DO','NRUNIC', @NRUNIC  output, @VNRUNIC output, ''	
	
	if @update=0 and (not exists(select 1 from doc where Numar=@numar and tip=@tip and data=@data and cod_tert=@tert))
		begin 	
		if exists(select top 1 numar from pozdoc where Numar=@numar and tip=@tip and month(data)=month(@data) and @NRUNIC=1 and @VNRUNIC=1)
			begin
				set @mesajeroare='wValidareNumereDoc: Numarul acesta de document a fost deja utilizat in decursul acestei luni!!'
				raiserror(@mesajeroare,11,1)
				return -1
			end
		else
			if exists(select top 1 numar from pozdoc where Numar=@numar and tip=@tip and YEAR(data)=year(@data) and @NRUNIC=1 and @VNRUNIC=0)
				begin
					set @mesajeroare='wValidareNumereDoc: Numarul acesta de document a fost deja utilizat in decursul acestui an!!'
					raiserror(@mesajeroare,11,1)
					return -1
				end
			else		
				
				if exists(select top 1 numar from pozdoc where Numar=@numar and @NRUNIC=1 and @VNRUNIC=3)
					begin
						set @mesajeroare='wValidareNumereDoc: Numarul acesta de document a fost deja utilizat!!'
						raiserror(@mesajeroare,11,1)
						return -1
						end			
		end	
return 0		
end
