--***

CREATE procedure wScriuCoefAm @sesiune varchar(50), @parXML xml
as  

Declare @update bit, @dur float, @o_dur float,
	@col2 float,@col3 float,@col4 float,@col5 float,@col6 float,@col7 float,@col8 float

Set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
Set @dur = @parXML.value('(/row/@dur)[1]','float')
Set @o_dur= isnull(@parXML.value('(/row/@o_dur)[1]','float'),0)
Set @col2 = isnull(@parXML.value('(/row/@col2)[1]','float'),0)
Set @col3 = isnull(@parXML.value('(/row/@col3)[1]','float'),0)
Set @col4 = isnull(@parXML.value('(/row/@col4)[1]','float'),0)
Set @col5 = isnull(@parXML.value('(/row/@col5)[1]','float'),0)
Set @col6 = isnull(@parXML.value('(/row/@col6)[1]','float'),0)
Set @col7 = isnull(@parXML.value('(/row/@col7)[1]','float'),0)
Set @col8 = isnull(@parXML.value('(/row/@col8)[1]','float'),0)

begin try
	/*if exists (select 1 from sys.objects where name='wScriuCoefAmSP' and type='P')  
	begin
		exec wScriuCoefAmSP @sesiune, @parXML
		return
	end*/ --sp_help Coefmf

	if @update=1 and isnull(@dur,0)<>@o_dur
	begin
		raiserror('Nu este permisa schimbarea duratei normale de utilizare!',11,1)
		return
	end
	
	if isnull(@dur,0)=0
	begin
		raiserror('Durata normala de utilizare necompletata!',11,1)
		return
	end
	
	if @update=1  
	begin  
		update coefMF set col2=@col2, col3=@col3, col4=@col4, col5=@col5, col6=@col6, col7=@col7, 
			col8=@col8
			where dur = @dur
	end  
	else   
	begin
		declare @dur_par float    
		/*if (isnull(@dur,'')='')  	
			exec wMaxdur 'dur','nomencl',@dur_par output
		else */
			set @dur_par=@dur --select * from Coefmf
		insert into Coefmf (Dur, col2, col3, col4, col5, col6, col7, col8)
			values (@dur_par, @col2, @col3, @col4, @col5, @col6, @col7, @col8)
	end
	
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch 
