--***
Create
procedure [dbo].[wOPGenCoefAm] @sesiune varchar(50), @parXML xml
as

declare @dur int, @col2 decimal(6,2), @col3 decimal(6,2), @col4 decimal(6,2), @col5 decimal(6,2), 
@col6 decimal(6,2), @col7 decimal(6,2), @col8 decimal(6,2), @data datetime, @userASiS varchar(10)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @data=getdate()

begin try  
	--BEGIN TRAN
	/*if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)*/
	delete from coefMF
	set @dur=1
	WHILE @dur<=100
	begin
		set @col2=round(100/@dur,1)
		set @col3=(case when @dur<6 then @col2*1.5 when @dur<11 then @col2*2 else @col2*2.5 end)
		set @col4=round(100/@col3,0)
		set @col5=(case when @dur<6 then @dur else @dur-@col4 end)
		set @col6=@col5-@col4
		set @col7=@col5-@col6
		set @col8=@dur-@col5
		insert into coefMF (Dur,Col2,Col3,Col4,Col5,Col6,Col7,Col8)
			values (@dur,@Col2,@Col3,@Col4,@Col5,@Col6,@Col7,@Col8)
		set @dur=@dur+1
	end

	select 'Terminat operatie!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
