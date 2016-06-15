
CREATE procedure [dbo].[wOPAdaugareResursa] @sesiune varchar(50), @parXML XML  
as
	declare @idp int, @tip varchar(1), @cod varchar(20),@cantitate float, @pret float,@lm varchar(20)
	
	set @idp = isnull(@parXML.value('(/parametri/@i_idp)[1]', 'int'), 0)
	set @tip =isnull(@parXML.value('(/parametri/@i_tip)[1]', 'varchar(1)'), '')
	set @cod= isnull(@parXML.value('(/parametri/@i_cod)[1]', 'varchar(20)'), '')
	set @cantitate=isnull(@parXML.value('(/parametri/@i_cantitate)[1]', 'float'), 0)
	set @pret= isnull(@parXML.value('(/parametri/@i_pret)[1]', 'float'), 0)
	set @lm= isnull(@parXML.value('(/parametri/@i_lm)[1]', 'varchar(20)'), '')
	
	if @idp = 0 
	begin
		raiserror('ID Parinte nu poate avea valoarea 0!',11,1)
		return -1
	end		
	else
	--Adaugare M,O,R,S ca si copil al unui parinte de tip S,R sau T
	begin
		if (select tip from pozTehnologii where id=@idp) not in ('S','R','T')
		begin			
			raiserror('ID Parinte introdus nu are tipul corespunzator',11,1)
			return -1	
		end			
		if @tip='' or @cod=''
		begin
			raiserror('Sunt campuri necompletate!',11,1)
			return -1				
		end
		if (select COUNT(*) from pozTehnologii where id=@idp) = 0
		begin
			raiserror('ID Parinte introdus nu are corespondent!',11,1)
			return -1			
		end		
		insert into pozTehnologii(tip,cod,cantitate,pret,resursa,idp) values( @tip,@cod,@cantitate,@pret,@lm,@idp)
	end
