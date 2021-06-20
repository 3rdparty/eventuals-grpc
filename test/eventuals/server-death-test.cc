#include "gtest/gtest.h"

#include "stout/task.h"

#include "stout/eventuals/grpc/client.h"

#include "stout/grpc/server.h"

// https://github.com/grpc/grpc/blob/master/examples/protos/keyvaluestore.proto
#include "examples/protos/keyvaluestore.grpc.pb.h"

#include "test/test.h"

using stout::borrowable;
using stout::Notification;

using stout::grpc::ServerBuilder;
using stout::grpc::Stream;

using stout::eventuals::grpc::Client;
using stout::eventuals::grpc::CompletionPool;
using stout::eventuals::grpc::Handler;

TEST_F(StoutEventualsGrpcTest, ServerDeathTest)
{
  // NOTE: need pipes to get the server's port, this also helps
  // synchronize when the server is ready to have the client connect.
  int pipefd[2];

  auto error = pipe(pipefd);

  ASSERT_NE(-1, error);

  auto server = [&]() {
    ServerBuilder builder;

    int port = 0;

    builder.AddListeningPort(
        "0.0.0.0:0",
        grpc::InsecureServerCredentials(),
        &port);

    auto build = builder.BuildAndStart();

    ASSERT_TRUE(build.status.ok());

    auto server = std::move(build.server);

    ASSERT_TRUE(server);

    auto serve = server->Serve<
      Stream<keyvaluestore::Request>,
      Stream<keyvaluestore::Response>>(
          "keyvaluestore.KeyValueStore.GetValues",
          [](auto&&) {
            exit(1);
          });

    ASSERT_TRUE(serve.ok());

    auto error = write(pipefd[1], &port, sizeof(int));

    ASSERT_LT(0, error);

    server->Wait();
  };

  std::thread thread([&]() {
    ASSERT_DEATH(server(), "");
  });

  int port = 0;

  error = read(pipefd[0], &port, sizeof(int));

  ASSERT_LT(0, error);

  borrowable<CompletionPool> pool;

  Client client(
      "0.0.0.0:" + stringify(port),
      grpc::InsecureChannelCredentials(),
      pool.borrow());

  auto call = [&]() {
    return client.Call<
      Stream<keyvaluestore::Request>,
      Stream<keyvaluestore::Response>>(
          "keyvaluestore.KeyValueStore.GetValues")
      | (Handler<grpc::Status>()
         .ready([](auto& call) {
           keyvaluestore::Request request;
           request.set_key("0");
           call.WriteLast(request);
         }));
  };

  auto status = *call();

  ASSERT_EQ(grpc::UNAVAILABLE, status.error_code());

  thread.join();

  close(pipefd[0]);
  close(pipefd[1]);
}