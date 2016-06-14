declare @test varchar(max)
select @test='goto testgoto'

exec (@test)

print '1'

testgoto:
print '2'