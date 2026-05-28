import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ProviderModule } from './modules/provider/provider.module';
import { UserModule } from './user/user.module';

@Module({
  imports: [ProviderModule, UserModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
