--***
CREATE procedure  [dbo].[wScriuPozSesizari] 
@sesiune varchar(50), @parXML xml
as


declare @subiect varchar(100), @descriere varchar(400), @cod_utilizator varchar(10), @data datetime, @ore varchar(10),
		@descriere_sesizare varchar(400), @subiect_sesizare varchar(200), @stare varchar(20), @tip varchar(20), 
		@obs_existente varchar(200), @tip_op varchar(5), @tip_sarcina varchar(5), @cod_sesizare varchar(15),
		@tip_nou varchar(5), @stare_noua varchar(5),@aplicatie_sesizare varchar(5), @rasp_sesizare varchar(200), 
		@obs_sesizare varchar(200),@i_aplicatie varchar(2),@i_client varchar(50),@i_pers varchar(20),@i_subiect varchar(100),
		@docXMLIaPozSesizari xml, @client varchar(50), @update varchar(1), @i_sistem varchar(20)
		
select	

	@descriere_sesizare = rtrim (isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(400)'), '')),
	@subiect_sesizare = rtrim (isnull(@parXML.value('(/row/@descrieres)[1]', 'varchar(200)'), '')),
	@stare = rtrim (isnull(@parXML.value('(/row/@stare)[1]', 'varchar(10)'), '')),
	@tip = rtrim (isnull(@parXML.value('(/row/@tip)[1]', 'varchar(10)'), '')),
	@obs_existente= rtrim (isnull(@parXML.value('(/row/@observatii)[1]', 'varchar(200)'), '')),	
	@cod_sesizare= rtrim (isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')),
	@aplicatie_sesizare=  rtrim (isnull(@parXML.value('(/row/@aplicatie)[1]', 'varchar(15)'), '')),
	@obs_sesizare= rtrim (isnull(@parXML.value('(/row/row/@i_observatii)[1]', 'varchar(200)'), '')),
	@tip_op = rtrim (isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(5)'), '')),
	@update = rtrim (isnull(@parXML.value('(/row/row/@update)[1]', 'varchar(5)'), ''))


--update sesizare, sarcina
if @update like '%1%' 
	begin
		declare @idses varchar(10), @idsar varchar(10)
			select
				@i_client = rtrim (isnull(@parXML.value('(/row/row/@client)[1]', 'varchar(50)'), '')),
				@i_aplicatie = rtrim (isnull(@parXML.value('(/row/row/@aplicatie)[1]', 'varchar(2)'), '')),
				@i_pers = rtrim (isnull(@parXML.value('(/row/row/@contact)[1]', 'varchar(20)'), '')),
				@i_sistem = rtrim (isnull(@parXML.value('(/row/row/@sistem)[1]', 'varchar(20)'), '')),
				@idses = rtrim (isnull(@parXML.value('(/row/row/@IDSesizare)[1]', 'varchar(10)'), '')),
				@idsar = rtrim (isnull(@parXML.value('(/row/row/@idsarcina)[1]', 'varchar(10)'), ''))
				
				update Sarcini set Proiect=@i_aplicatie , IDC = (case when @i_client= '' then IDC else @i_client end) where IDSarcina= @idsar
				update sesizari set Client= (case when @i_client= '' then Client else @i_client end),
				Aplicatie = @i_aplicatie , sistem= @i_sistem, Persoana_contact = (case when @i_pers= '' then Persoana_contact else @i_pers end)
				where cod = @idses
				
				
				
	end
else
begin
if (@tip_op = 'SA')	
		--adauga sarcina
		begin
			select
				@descriere = rtrim (isnull(@parXML.value('(/row/row/@i_descriere)[1]', 'varchar(400)'), '')),
				@subiect = rtrim (isnull(@parXML.value('(/row/row/@i_subiect)[1]', 'varchar(100)'), '')),
				@ore = rtrim (isnull(@parXML.value('(/row/row/@i_ore)[1]', 'varchar(10)'), '')),
				@tip_sarcina = rtrim (isnull(@parXML.value('(/row/row/@tip_sarcina)[1]', 'varchar(10)'), '')),	
				@cod_utilizator =rtrim ( isnull(@parXML.value('(/row/row/@i_utilizator)[1]', 'varchar(10)'), '')),
				@data =rtrim ( isnull(@parXML.value('(/row/row/@i_data)[1]', 'varchar(10)'), ''))
				
				insert into Sarcini values (@aplicatie_sesizare,isnull((select MAX(idsarcina) from sarcini where ISNUMERIC(idsarcina) =1)+1, 10001),
				GETDATE(),@tip_sarcina,(case when @subiect <> '' then @subiect else @subiect_sesizare end ) ,'',(case when @descriere <> '' then @descriere else @descriere_sesizare end),'A',
				(select idc from sesizari where cod = @cod_sesizare ),@cod_utilizator,'0',@ore,GETDATE(),
				 @data,'0','','',@cod_sesizare,'','','','','0','','1',GETDATE(),'','',0,'','','','')
				 if (@stare like '%Nepreluata%')
					update Sesizari set Stare='L' where cod = @cod_sesizare 
		end
else
	if (@tip_op ='ST')
	--modifica tip, stare, observatii,  raspuns
	begin		
		select
			@rasp_sesizare= rtrim (isnull(@parXML.value('(/row/row/@raspuns)[1]', 'varchar(10)'), '')),
			@stare_noua= rtrim (isnull(@parXML.value('(/row/row/@stareAC)[1]', 'varchar(10)'), '')),
			@tip_nou = rtrim (isnull(@parXML.value('(/row/row/@tipAC)[1]', 'varchar(10)'), ''))
		set @obs_existente = @obs_existente + @obs_sesizare
		

		
	-- finalizare
		if ( @stare_noua = '3' )
				update Sesizari set stare='F',tip_sesizare=(case when @tip_nou in ('A','D','S','V') then @tip_nou else Tip_sesizare end),
				observatii_validare =@obs_existente, raspuns= @rasp_sesizare where cod = @cod_sesizare
		else
		--luare in lucru
			if (@stare_noua = '2' )
				update Sesizari set stare='L',tip_sesizare=(case when @tip_nou in ('A','D','S','V') then @tip_nou else Tip_sesizare end),
				observatii_validare =@obs_existente, raspuns= @rasp_sesizare where cod = @cod_sesizare
				
				else 
				update Sesizari set tip_sesizare=(case when @tip_nou in ('A','D','S','V') then @tip_nou else Tip_sesizare end),
				observatii_validare =@obs_existente where cod = @cod_sesizare	
				
	end
	else
		--adauga sesizare
		begin
			declare @usr varchar(5)
			select
				@i_client = rtrim (isnull(@parXML.value('(/row/row/@client)[1]', 'varchar(50)'), '')),
				@i_aplicatie = rtrim (isnull(@parXML.value('(/row/row/@aplicatie)[1]', 'varchar(2)'), '')),
				@i_pers = rtrim (isnull(@parXML.value('(/row/row/@contact)[1]', 'varchar(20)'), '')),
				@i_sistem = rtrim (isnull(@parXML.value('(/row/row/@sistem)[1]', 'varchar(20)'), ''))
				
			set @cod_sesizare=(select MAX(cod) + 1  from Sesizari)
			declare @tert varchar(10)
			select 
				@tert = valoare from proprietati where tip = 'UTILIZATOR' and  cod_proprietate = 'DISTRIBUITOR' and cod like '%'+SUBSTRING(SUSER_NAME(),6,20)+'%'
			select @usr= valoare from (
					select cod,Cod_proprietate,valoare from proprietati where Tip='UTILIZATOR'  and cod like '%'+SUBSTRING(SUSER_NAME(),6,20)+'%' ) as p
						where p.cod_proprietate='PERSOANA'
			insert into Sesizari values ( @cod_sesizare,@tert,@subiect_sesizare, @descriere_sesizare, 'N','',GETDATE(),(select convert(char(6),replace(convert(time,GETDATE()),':',''))),
									getdate(),0, @i_client ,@i_pers,'','','','','','A',@i_aplicatie,0,0,0,0,'','','','','','',@i_sistem,'',0,0,'' )
							
		end
end

--refresh pozitii sesizare
set @docXMLIaPozSesizari ='<row cod="'+rtrim(@cod_sesizare)+'" />'
exec wIaPozSesizari @sesiune=@sesiune, @parXML=@docXMLIaPozSesizari
