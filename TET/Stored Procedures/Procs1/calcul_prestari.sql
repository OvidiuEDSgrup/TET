--***
create procedure calcul_prestari @sub char(9), @numar char(20), @data datetime, 
	@total_prestare float output, @total_asycuda float output 
as begin
	set @total_prestare=(select isnull(sum(dbo.rot_val(pret_valuta,2)), 0) from pozdoc 
	where subunitate=@sub and tip in ('RP', 'RZ') and gestiune_primitoare='' and numar=@numar and data=@data) 
	set @total_asycuda=(select isnull(sum(dbo.rot_val(suprataxe_vama,2)), 0) from pozdoc 
	where subunitate=@sub and tip in ('RP', 'RZ') and gestiune_primitoare='' and numar=@numar and data=@data) 
end 
