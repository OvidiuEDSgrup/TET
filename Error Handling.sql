use master;
go

if db_id(N'Test') is not null
begin
  drop database [Test];
end;
go

create database [Test];
go

use [Test];
go

create schema [Schema];
go

create procedure [Schema].[HandleModuleFailure]
  @schema sysname,
  @module sysname
with execute as caller
as
begin
  declare @errorNumber int = error_number();
  declare @errorSeverity int = error_severity();
  declare @errorState int = error_state();
  declare @errorProcedure nvarchar(126) = isnull(error_procedure(), N'<Unknown>');
  declare @errorLine int = isnull(error_line(), 0);
  declare @errorMessage nvarchar(2048) = isnull(error_message(), N'');

  raiserror (N'Error: Module [%s].[%s] unexpectedly failed with error number %d, severity %d, state %d, at [%s], line %d with the message "%s".',
             16, 0,
             @schema,
             @module,
             @errorNumber,
             @errorSeverity,
             @errorState,
             @errorProcedure,
             @errorLine,
             @errorMessage)
            with log;
end;
go

create procedure [Schema].[TestErrorHandling]
  @parameterError bit,
  @workError      bit
with execute as caller
as
begin
  set nocount on;

  -- Test for parameter errors.
  if @parameterError = 1
  begin
    raiserror(N'Parameter error.', 16, 0);

    return -1;  -- Argument error code.
  end
  else
  begin
    begin try
      declare @hasOuterTransaction bit = case when @@trancount > 0 then 1 else 0 end;
      declare @rollbackPoint nchar(32) = replace(convert(nchar(36), newid()), N'-', N'');

      if @hasOuterTransaction = 1
      begin
        save transaction @rollbackPoint;
      end
      else
      begin
        begin transaction @rollbackPoint;
      end;

      -- Do some work.
      if @workError = 1
      begin
        raiserror(N'Work error.', 16, 0);
      end;

      if @hasOuterTransaction = 0
      begin
        commit transaction;
      end;
    end try
    begin catch
      if xact_state() = 1
      begin
        rollback transaction @rollbackPoint;
      end;

      execute [Schema].[HandleModuleFailure]
        @schema = N'Schema',
        @module = N'TestErrorHandling';

      return -error_number();
    end catch;
  end;
end;
go

create table [Schema].[Table]
(
  [Id] int         identity not null primary key,
  [ParameterError] bit not null,
  [WorkError]      bit not null
);
go

create trigger [Schema].[Trigger] on [Schema].[Table]
  for insert
as
begin
  -- Test for errors.
  if exists (select * from inserted as I where I.[ParameterError] = 1)
  begin
    rollback transaction;

    raiserror(N'Parameter error.', 16, 0);

    return;
  end
  else
  begin
    begin try
      -- Do some work.
      if exists (select * from inserted as I where I.[WorkError] = 1)
      begin
        raiserror(N'Work error.', 16, 0);
      end;
    end try
    begin catch
      rollback transaction;
       
      execute [Schema].[HandleModuleFailure]
        @schema = N'Schema',
        @module = N'TestErrorHandling';

      return;
    end catch;
  end;
end;
go

-- Tests
-- Stored procedures
print N'Stored procedure tests.'
print N'-----------------------';
print N'';

print N'No outer transaction, no try-catch, no errors.';

declare @result int;

execute @result = [Schema].[TestErrorHandling]
  @parameterError = 0,
  @workError = 0;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, no try-catch, parameter error.';

declare @result int;

execute @result = [Schema].[TestErrorHandling]
  @parameterError = 1,
  @workError = 0;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, no try-catch, work error.';

declare @result int;

execute @result = [Schema].[TestErrorHandling]
  @parameterError = 0,
  @workError = 1;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, no errors.';

declare @result int;

begin transaction;
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 0,
    @workError = 0;
commit transaction;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, parameter error.';

declare @result int;

begin transaction;
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 1,
    @workError = 0;
commit transaction;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, work error.';

declare @result int;

begin transaction;
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 0,
    @workError = 1;
commit transaction;

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, no errors.';

declare @result int;

begin try
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 0,
    @workError = 0;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, parameter error.';

declare @result int;

begin try
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 1,
    @workError = 0;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, work error.';

declare @result int;

begin try
  execute @result = [Schema].[TestErrorHandling]
    @parameterError = 0,
    @workError = 1;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, no errors.';

declare @result int;

begin try
  begin transaction;
    execute @result = [Schema].[TestErrorHandling]
      @parameterError = 0,
      @workError = 0;
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, parameter error.';

declare @result int;

begin try
  begin transaction;
    execute @result = [Schema].[TestErrorHandling]
      @parameterError = 1,
      @workError = 0;
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();

  rollback transaction;
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, work error.';

declare @result int;

begin try
  begin transaction;
    execute @result = [Schema].[TestErrorHandling]
      @parameterError = 0,
      @workError = 1;
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();

  rollback transaction;
end catch

print N'Result: ' + isnull(convert(nvarchar(10), @result), N'null') + N'; Transaction count: ' + convert(nvarchar(10), @@trancount);
go

-- Triggers
print N'';
print N'Trigger tests.'
print N'--------------';
print N'';

print N'No outer transaction, no try-catch, no errors.';

insert into [Schema].[Table] ([ParameterError], [WorkError])
  values (0, 0);

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go


print N'';
print N'No outer transaction, no try-catch, parameter error.';

insert into [Schema].[Table] ([ParameterError], [WorkError])
  values (1, 0);

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, no try-catch, work error.';

insert into [Schema].[Table] ([ParameterError], [WorkError])
  values (0, 1);

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, no errors.';

begin transaction;
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (0, 0);
commit transaction;

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, parameter error.';

begin transaction;
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (1, 0);
commit transaction;

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, no try-catch, work error.';

begin transaction;
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (0, 1);
commit transaction;

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, no errors.';

begin try
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (0, 0);
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, parameter error.';

begin try
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (1, 0);
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'No outer transaction, try-catch, work error.';

begin try
  insert into [Schema].[Table] ([ParameterError], [WorkError])
    values (0, 1);
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, no errors.';

begin try
  begin transaction;
    insert into [Schema].[Table] ([ParameterError], [WorkError])
      values (0, 0);
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, parameter error.';

declare @result int;

begin try
  begin transaction;
    insert into [Schema].[Table] ([ParameterError], [WorkError])
      values (1, 0);
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go

print N'';
print N'Outer transaction, try-catch, work error.';

declare @result int;

begin try
  begin transaction;
    insert into [Schema].[Table] ([ParameterError], [WorkError])
      values (0, 1);
  commit transaction;
end try
begin catch
  print N'Catch: ' + error_message();
end catch

print N'Transaction count: ' + convert(nvarchar(10), @@trancount);
go
